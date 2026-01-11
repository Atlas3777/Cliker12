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
        var ext = Path.GetExtension(fileName);
        var key = $"avatars/{Guid.NewGuid()}{ext}";

        var request = new PutObjectRequest
        {
            BucketName = _bucketName,
            Key = key,
            InputStream = fileStream,
            ContentType = contentType,
        };
        
        try
        {
            await _s3Client.PutObjectAsync(request);
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Error uploading object: {ex.Message}");
            throw;
        }

        return $"https://storage.yandexcloud.net/{_bucketName}/{key}";
    }
}