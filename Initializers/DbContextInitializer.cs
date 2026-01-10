using CSharpClicker.Web.Domain;
using CSharpClicker.Web.Infrastructure.DataAccess;
using Microsoft.EntityFrameworkCore;

namespace CSharpClicker.Web.Initializers;

public static class DbContextInitializer
{
    public static void AddAppDbContext(IServiceCollection services, IConfiguration configuration)
    {
        // Берем строку подключения из переменных окружения (для Docker/Cloud)
        var connectionString = configuration.GetConnectionString("DefaultConnection");

        services.AddDbContext<AppDbContext>(options =>
            options.UseNpgsql(connectionString));
    }

    public static void InitializeDbContext(AppDbContext appDbContext)
    {
        const string Boost1 = "brodaga";
        const string Boost2 = "bita";
        const string Boost3 = "laser";
        const string Boost4 = "pal";
        const string Boost5 = "gat";
        const string Boost6 = "mult";

        appDbContext.Database.Migrate();
       
        var existingBoosts = appDbContext.Boosts
            .ToArray();
        
        AddBoostIfNotExist(Boost1, price: 100, profit: 1, mult: 0, isAuto: true);
        AddBoostIfNotExist(Boost2, price: 500, profit: 5, mult: 0);
        AddBoostIfNotExist(Boost3, price: 2000, profit: 25, mult: 0);
        AddBoostIfNotExist(Boost4, price: 10000, profit: 400,mult: 0, isAuto: true);
        AddBoostIfNotExist(Boost5, price: 100000, profit: 1000);
        AddBoostIfNotExist(Boost6, price: 250, profit: 0, mult: 1);

        //AddRandomUsers();

        appDbContext.SaveChanges();

        void AddRandomUsers()
        {
            const int limit = 130000534;
            const int asciLimit = 126;
            const int symbolsLimit = 15;
            const int symbolsStart = 5;

            var random = new Random();

            for (var i = 0; i < 200; i++)
            {
                var score = random.Next(limit);
                var symbolsCount = random.Next(symbolsStart, symbolsLimit);

                var userName = string.Empty;
                for (var j = 0; j < symbolsCount; j++)
                {
                    var character = random.Next(asciLimit);
                    userName += char.ConvertFromUtf32(character);
                }

                appDbContext.Users.Add(new ApplicationUser
                {
                    UserName = userName,
                    RecordScore = score,
                });
            }
        }

        void AddBoostIfNotExist(string name, long price, long profit, int mult = 0, bool isAuto = false)
        {
            if (!existingBoosts.Any(eb => eb.Title == name))
            {
                var pathToImage = Path.Combine(".", "Resources", "BoostImages", $"{name}.png");
                using var fileStream = File.OpenRead(pathToImage);
                using var memoryStream = new MemoryStream();

                fileStream.CopyTo(memoryStream);

                appDbContext.Boosts.Add(new Boost
                {
                    Title = name,
                    Price = price,
                    Profit = profit,
                    IsAuto = isAuto,
                    Image = memoryStream.ToArray(),
                    ZoneClickMultiplayer = mult,
                });
            }
        }
}}