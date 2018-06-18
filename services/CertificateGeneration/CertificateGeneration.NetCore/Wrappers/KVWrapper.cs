using System;
using Microsoft.IdentityModel.Clients.ActiveDirectory;
using System.Threading.Tasks;
using Microsoft.Extensions.Configuration;
using Microsoft.Azure.KeyVault;

namespace CertificateGeneration.Wrappers
{
    public interface IKVWrapper
    {
        Task UploadPem(string vaultBaseUrl, string secretName, string pem);
        Task UploadPfx(string vaultBaseUrl, string certificateName, string base64EncodedCertificate);
    }

    public class KVWrapper : IKVWrapper
    {
        public KVWrapper(IConfiguration configuration)
        {
            client = new KeyVaultClient(new KeyVaultClient.AuthenticationCallback(this.GetToken));
            Configuration = configuration;
        }

        //this is an optional property to hold the secret after it is retrieved
        //the method that will be provided to the KeyVaultClient
        private async Task<string> GetToken(string authority, string resource, string scope)
        {
            var authContext = new AuthenticationContext(authority);
            ClientCredential clientCred = new ClientCredential(Configuration.GetValue<string>("ClientId"),
                                                               Configuration.GetValue<string>("ClientSecret"));
            AuthenticationResult result = await authContext.AcquireTokenAsync(resource, clientCred);

            if (result == null)
                throw new InvalidOperationException("Failed to obtain the JWT token");

            return result.AccessToken;
        }

        public async Task UploadPem(string vaultBaseUrl, string secretName, string pem)
        {
            var bundle = await client.SetSecretAsync(vaultBaseUrl,
                                                 secretName,
                                                 pem);
        }

        public async Task UploadPfx(string vaultBaseUrl, string certificateName, string base64EncodedCertificate)
        {
            var bundle = await client.ImportCertificateAsync(vaultBaseUrl,
                                                     certificateName,
                                                     base64EncodedCertificate);
        }

        private KeyVaultClient client;
        private readonly IConfiguration Configuration;
    }
}