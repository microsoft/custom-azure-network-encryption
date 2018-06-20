using Microsoft.VisualStudio.TestTools.UnitTesting;
using CertificateGeneration.Wrappers;
using System;
using System.Security.Cryptography;
using System.Runtime.InteropServices;

namespace CertificateGenerationTests.Wrappers
{
    [TestClass()]
    public class CertificatesWrapperTests
    {
        [TestMethod()]
        public void GenerateCertificateTest_ValidInputGeneratesCert()
        {
            // arrange
            var certificatesWrapper = new CertificatesWrapper();
            CertificateProperties properties = new CertificateProperties
            {
                SubjectName = "CN=microsoft",
                ValidDays = 1
            };

            // act
            var cert = certificatesWrapper.GenerateCertificate(properties);

            // assert
            Assert.IsNotNull(cert);
        }

        [TestMethod()]
        public void GenerateCertificateTest_ValidKeyStrengthGeneratesCert()
        {
            // arrange
            var certificatesWrapper = new CertificatesWrapper();
            CertificateProperties properties = new CertificateProperties
            {
                SubjectName = "CN=microsoft",
                ValidDays = 1,
                KeyStrength = 1024
            };

            // act
            var cert = certificatesWrapper.GenerateCertificate(properties, null);

            // assert
            Assert.IsNotNull(cert);
        }

        [TestMethod()]
        public void GenerateCertificateTest_InvalidSubjectNameThrowsException()
        {
            // arrange
            var certificatesWrapper = new CertificatesWrapper();
            CertificateProperties properties = new CertificateProperties
            {
                SubjectName = "www.microsoft.com",
                ValidDays = 1
            };

            // act and assert
            if (RuntimeInformation.IsOSPlatform(OSPlatform.Windows))
            {
                // When runs on Windows, it throws different exception.
                try
                {
                    certificatesWrapper.GenerateCertificate(properties);
                }
                catch (Exception e)
                {
                    Assert.AreEqual("The string contains an invalid X500 name attribute key, oid, value or delimiter", e.Message);
                    return;
                }
                // Exception was expected.
                Assert.Fail();
            }
            else
            {
                Assert.ThrowsException<CryptographicException>(() => certificatesWrapper.GenerateCertificate(properties));
            }
        }

        [TestMethod()]
        public void GenerateCertificateTest_InvalidKeyStrengthThrowsException()
        {
            // arrange
            var certificatesWrapper = new CertificatesWrapper();
            CertificateProperties properties = new CertificateProperties
            {
                SubjectName = "CN=microsoft",
                ValidDays = 1,
                KeyStrength = 2
            };

            // act and assert
            Assert.ThrowsException<CryptographicException>(() => certificatesWrapper.GenerateCertificate(properties, null));
        }
    }
}