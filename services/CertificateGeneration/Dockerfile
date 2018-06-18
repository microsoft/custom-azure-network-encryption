FROM microsoft/dotnet:2.0-sdk AS build
WORKDIR /app

COPY *.sln .
COPY CertificateGeneration.NetCore/*.csproj ./CertificateGeneration.NetCore/
COPY CertificateGenerationTests.NetCore/*.csproj ./CertificateGenerationTests.NetCore/

RUN dotnet restore

COPY CertificateGeneration.NetCore/. ./CertificateGeneration.NetCore/
COPY CertificateGenerationTests.NetCore/. ./CertificateGenerationTests.NetCore/

#RUN dotnet build --configuration Release
RUN dotnet publish -c Release -o out -r linux-x64

FROM build as test
WORKDIR /app/CertificateGenerationTests.NetCore
RUN dotnet test

FROM microsoft/dotnet:2.0-runtime as runtime
ENV ASPNETCORE_URLS "http://0.0.0.0:5000"
WORKDIR /app
COPY --from=build /app/CertificateGeneration.NetCore/out/ ./
ENTRYPOINT ["dotnet", "/app/CertificateGeneration.NetCore.dll"]