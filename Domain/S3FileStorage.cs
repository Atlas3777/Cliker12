using Amazon.S3;
using Amazon.S3.Model;

namespace CSharpClicker.Web.Infrastructure.Implementations;

public interface IFileStorage
{
    Task<string> UploadFileAsync(Stream fileStream, string fileName, string contentType);
}

public class S3FileStorage : IFileStorage
{
    private readonly IAmazonS3 _s3Client;
    private readonly string _bucketName;

    public S3FileStorage(IAmazonS3 s3Client, IConfiguration configuration)
    {
        _s3Client = s3Client;
        _bucketName = configuration["YandexCloud:BucketName"] 
                      ?? throw new ArgumentNullException("BucketName not configured");
    }

    public async Task<string> UploadFileAsync(Stream fileStream, string fileName, string contentType)
    {
        var key = $"avatars/{Guid.NewGuid()}_{fileName}";
        
        var request = new PutObjectRequest
        {
            BucketName = _bucketName,
            Key = key,
            InputStream = fileStream,
            ContentType = contentType,
            CannedACL = S3CannedACL.PublicRead 
        };

        await _s3Client.PutObjectAsync(request);

        return $"https://storage.yandexcloud.net/{_bucketName}/{key}";
    }
}