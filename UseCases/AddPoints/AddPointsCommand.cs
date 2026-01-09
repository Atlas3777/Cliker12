using CSharpClicker.Web.UseCases.Common;
using MediatR;

namespace CSharpClicker.Web.UseCases.AddPoints;

public record AddPointsCommand(int Seconds, int clicksOnMap, int clicksOnRedZone) : IRequest<ScoreDto> { }

