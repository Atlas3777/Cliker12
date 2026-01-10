namespace CSharpClicker.Web.UseCases.GetLeaderboard;

public class LeaderboardUserDto
{
    public string UserName { get; init; }
    public long RecordScore { get; init; }

    public string? AvatarUrl { get; init; }
}
