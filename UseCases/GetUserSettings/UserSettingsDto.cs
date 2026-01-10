namespace CSharpClicker.Web.UseCases.GetUserSettings;

public record UserSettingsDto
{
    public string UserName { get; init; }

    public string? AvatarUrl { get; init; }
}
