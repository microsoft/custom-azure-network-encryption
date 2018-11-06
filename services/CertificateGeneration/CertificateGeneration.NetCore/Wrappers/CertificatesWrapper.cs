using System;
using System.Text;
using System.Security.Cryptography;
using System.Security.Cryptography.X509Certificates;

namespace CertificateGeneration.Wrappers
{
    public class CertificateProperties
    {
        public string SubjectName { get; set; }
        public int ValidDays { get; set; }
        public bool BasicConstraintCertificateAuthority { get; set; } = false;
        public bool BasicConstraintHasPathLengthConstraint { get; set; } = false;
        public int BasicConstraintPathLengthConstraint { get; set; } = 0;
        public bool BasicConstraintCritical { get; set; } = false;
        public int KeyStrength { get; set; } = 2048;
        public int SerialNumber { get; set; }
    }

    public interface ICertificatesWrapper
    {
        X509Certificate2 GenerateCertificate(CertificateProperties properties, X509Certificate2 ca = null);
        string ExportToPEM(X509Certificate2 cert);
        string ExportToPfx(X509Certificate2 cert);
    }

    public class CertificatesWrapper : ICertificatesWrapper
    {
        public X509Certificate2 GenerateCertificate(CertificateProperties properties, X509Certificate2 ca = null)
        {
            var random = new Random(DateTime.Now.Millisecond);
            RSA key = RSA.Create(properties.KeyStrength);
            CertificateRequest req = new CertificateRequest(
                properties.SubjectName,
                key,
                HashAlgorithmName.SHA256,
                RSASignaturePadding.Pkcs1);

            var notBefore = DateTime.UtcNow;
            var notAfter = notBefore.AddDays(properties.ValidDays);

            req.CertificateExtensions.Add(new X509BasicConstraintsExtension(properties.BasicConstraintCertificateAuthority,
                                                                            properties.BasicConstraintHasPathLengthConstraint,
                                                                            properties.BasicConstraintPathLengthConstraint,
                                                                            properties.BasicConstraintCritical));
            req.CertificateExtensions.Add(new X509SubjectKeyIdentifierExtension(req.PublicKey, false));
            if (ca == null)
            {
                return req.CreateSelfSigned(notBefore, notAfter);
            }
            else
            {
                byte[] serialNumber = BitConverter.GetBytes(properties.SerialNumber);

                var cert = req.Create(ca, notBefore, notAfter, serialNumber);
                return cert.CopyWithPrivateKey(key);
            }
        }

        public string ExportToPEM(X509Certificate2 cert)
        {
            StringBuilder builder = new StringBuilder();

            builder.AppendLine("-----BEGIN CERTIFICATE-----");
            builder.AppendLine(Convert.ToBase64String(cert.Export(X509ContentType.Cert), Base64FormattingOptions.InsertLineBreaks));
            builder.AppendLine("-----END CERTIFICATE-----");

            return builder.ToString();
        }

        public string ExportToPfx(X509Certificate2 cert)
        {
            return Convert.ToBase64String(cert.Export(X509ContentType.Pfx));
        }
    }
}