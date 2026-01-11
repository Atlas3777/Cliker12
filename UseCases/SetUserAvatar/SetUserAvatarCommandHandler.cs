using CSharpClicker.Web.Infrastructure.Abstractions;
using CSharpClicker.Web.Infrastructure.Implementations; // Добавь using
using MediatR;
using Microsoft.EntityFrameworkCore;

namespace CSharpClicker.Web.UseCases.SetUserAvatar;

public class SetUserAvatarCommandHandler : IRequestHandler<SetUserAvatarCommand, Unit>
{
    private readonly ICurrentUserAccessor currentUserAccessor;
    private readonly IAppDbContext appDbContext;
    private readonly IFileStorage fileStorage; 

    public SetUserAvatarCommandHandler(
        ICurrentUserAccessor currentUserAccessor, 
        IAppDbContext appDbContext,
        IFileStorage fileStorage)
    {
        this.currentUserAccessor = currentUserAccessor;
        this.appDbContext = appDbContext;
        this.fileStorage = fileStorage;
    }

    public async Task<Unit> Handle(SetUserAvatarCommand request, CancellationToken cancellationToken)
    {
        var userId = currentUserAccessor.GetCurrentUserId();
        var user = await appDbContext.ApplicationUsers.FirstAsync(user => user.Id == userId, cancellationToken);

        using var stream = request.Avatar.OpenReadStream();
        var url = await fileStorage.UploadFileAsync(stream, request.Avatar.FileName, request.Avatar.ContentType);

        user.AvatarUrl = url; 
        
        await appDbContext.SaveChangesAsync(cancellationToken);
        return Unit.Value;
    }
}