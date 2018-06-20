using System;
using System.Collections.Generic;
using Microsoft.AspNetCore.Mvc;
using System.Threading.Tasks;
using System.Security.Cryptography.X509Certificates;

using CertificateGeneration.Wrappers;

namespace CertificateGeneration.Controllers
{
    public class CertificateRequestProperties
    {
        public CertificateProperties CertificateProperties { get; set; }
        public string KeyVaultCertificateName { get; set; }
        public string KeyVaultSecretName { get; set; }
    }

    public class CertificatesRequest
    {
        public CertificateRequestProperties[] RequestsProperties { get; set; }
        public string IssuerBase64Pfx { get; set; }
        public string VaultBaseUrl { get; set; }
    }

    public class ResultJson
    {
        public string pfx { get; set; }
        public string result { get; set; }
    }

    [Route("api/[controller]")]
    public class CertificatesController : Controller
    {
        private IKVWrapper KvWrapper { get; set; }
        private ICertificatesWrapper CertificatesWrapper { get; set; }

        public CertificatesController(IKVWrapper kvWrapper, ICertificatesWrapper certificatesWrapper)
        {
            KvWrapper = kvWrapper;
            CertificatesWrapper = certificatesWrapper;
        }

        [HttpPost]
        public async Task<IActionResult> GenerateCertificatesAsync([FromBody] CertificatesRequest request)
        {
            // validate that we received a valid CertificatesRequest request body
            if (string.IsNullOrWhiteSpace(request?.VaultBaseUrl) 
                || request.RequestsProperties == null 
                || request.RequestsProperties.Length == 0)
            {
                return BadRequest();
            }

            try
            {
                X509Certificate2 issuerX509 = ! string.IsNullOrWhiteSpace(request.IssuerBase64Pfx)
                    ? new X509Certificate2(Convert.FromBase64String(request.IssuerBase64Pfx), "",
                        X509KeyStorageFlags.Exportable)
                    : null;

                var tasks = new List<Task<ResultJson>>();
                foreach (var requestProperties in request.RequestsProperties)
                {
                    tasks.Add(GenerateCertificateAsync(requestProperties, request.VaultBaseUrl, issuerX509));
                }

                await Task.WhenAll(tasks);

                var result = new List<ResultJson>();
                foreach (var task in tasks)
                {
                    result.Add(task.Result);
                }

                return Ok(result);
            }
            catch (Exception exception)
            {
                //TODO: log exception
                Console.WriteLine(exception.Message);
                return StatusCode(500);
            }
        }

        private async Task<ResultJson> GenerateCertificateAsync(CertificateRequestProperties properties, string vaultBaseUrl, X509Certificate2 issuerX509)
        {
            var result = new ResultJson();
            try
            {
                var x = CertificatesWrapper.GenerateCertificate(properties.CertificateProperties, issuerX509);
                result.pfx = CertificatesWrapper.ExportToPfx(x);

                if (properties.KeyVaultCertificateName != "")
                {
                    await KvWrapper.UploadPfx(vaultBaseUrl, properties.KeyVaultCertificateName, result.pfx);
                }

                if (properties.KeyVaultSecretName != "")
                {
                    await KvWrapper.UploadPem(vaultBaseUrl, properties.KeyVaultSecretName, CertificatesWrapper.ExportToPEM(x));
                }

                result.result = "Success";
            }
            catch (Exception exception)
            {
                //TODO: log exception
                Console.WriteLine(exception);
                throw;
            }

            return result;
        }
    }
}
