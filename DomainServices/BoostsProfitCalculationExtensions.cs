using CSharpClicker.Web.Domain;

namespace CSharpClicker.Web.DomainServices;

public static class BoostsProfitCalculationExtensions
{
    public static long GetProfit(this IEnumerable<UserBoost> userBoosts, bool shouldCalculateAutoBoosts = false)
    {
        if (shouldCalculateAutoBoosts)
        {
            return userBoosts
                .Where(ub => ub.Boost.IsAuto)
                .Sum(ub => ub.Quantity * ub.Boost.Profit);
        }

        return 1 + userBoosts
                .Where(ub => !ub.Boost.IsAuto)
                .Sum(ub => ub.Quantity * ub.Boost.Profit);
    }
    public static int GetMult(this IEnumerable<UserBoost> userBoosts)
    {
        return 2 + userBoosts
            .Sum(ub => ub.Quantity * ub.Boost.ZoneClickMultiplayer);
    }
}
