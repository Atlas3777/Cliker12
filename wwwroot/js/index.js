const threshold = 10;
let seconds = 0;
let clicks = 0;
let clicksOnMap = 0;   // Переменная для отслеживания кликов по карте
let clicksOnRedZone = 0; // Переменная для отслеживания кликов по красной зоне
const currentScoreElement = document.getElementById("current_score");
const recordScoreElement = document.getElementById("record_score");
const profitPerClickElement = document.getElementById("profit_per_click");
const profitPerSecondElement = document.getElementById("profit_per_second");
const multRedZoneElement = document.getElementById("red_zone_text");
const mapElement = document.getElementById("clickitem");

let currentScore = Number(currentScoreElement.innerText) || 0;
let recordScore = Number(recordScoreElement.innerText) || 0;
let profitPerSecond = Number(profitPerSecondElement.innerText);
let profitPerClick = Number(profitPerClickElement.innerText);
let multRedZone = Number(multRedZoneElement.innerText);

const redZoneElement = document.createElement("div");
redZoneElement.id = "red-zone";
redZoneElement.style.position = "absolute";
redZoneElement.style.width = "100px";
redZoneElement.style.height = "100px";
redZoneElement.style.backgroundColor = "red";
redZoneElement.style.borderRadius = "50%";
redZoneElement.style.cursor = "pointer";

document.body.appendChild(redZoneElement);

$(document).ready(function () {
    document.getElementById("red-zone").style.display = "block";
    redZoneElement.onclick = () => click(true);


    setInterval(moveRedZone, 10000);
    moveRedZone();

    window.addEventListener("resize", () => {
        updateRedZoneSize();
        updateRedZonePosition();
    });

    const clickitem = document.getElementById("clickitem");

    clickitem.onclick = ()=>click(false);

    setInterval(addSecond, 1000)

    const boostButtons = document.getElementsByClassName("boost-button");
    for (let i = 0; i < boostButtons.length; i++) {
        const boostButton = boostButtons[i];
        boostButton.onclick = () => boostButtonClick(boostButton);
    }

    toggleBoostsAvailability();
});


function moveRedZone() {
    const mapRect = mapElement.getBoundingClientRect();
    const randomX = Math.random() * (mapRect.width - 100);
    const randomY = Math.random() * (mapRect.height - 100);

    redZoneElement.style.left = `${mapRect.left + randomX}px`;
    redZoneElement.style.top = `${mapRect.top + randomY}px`;

    updateRedZonePosition(); // Обновляем позицию при изменении окна
}

function updateRedZonePosition() {
    const mapRect = mapElement.getBoundingClientRect();

    const redZoneX = parseFloat(redZoneElement.style.left) || mapRect.left;
    const redZoneY = parseFloat(redZoneElement.style.top) || mapRect.top;

    // Проверяем, чтобы зона оставалась в пределах изображения
    const clampedX = Math.max(mapRect.left, Math.min(mapRect.right - 100, redZoneX));
    const clampedY = Math.max(mapRect.top, Math.min(mapRect.bottom - 100, redZoneY));

    redZoneElement.style.left = `${clampedX}px`;
    redZoneElement.style.top = `${clampedY}px`;
}

function updateRedZoneSize() {
    const mapRect = mapElement.getBoundingClientRect();

    // Размер красной зоны как процент от ширины изображения
    const redZoneSize = Math.min(mapRect.width, mapRect.height) * 0.1;

    redZoneElement.style.width = `${redZoneSize}px`;
    redZoneElement.style.height = `${redZoneSize}px`;

    updateRedZonePosition(); // Обновляем позицию, чтобы зона оставалась внутри изображения
}



function boostButtonClick(boostButton) {
    if (clicks > 0 || seconds > 0) {
        addPointsToScore();
    }
    buyBoost(boostButton);
}

function buyBoost(boostButton) {
    const boostIdElement = boostButton.getElementsByClassName("boost-id")[0];
    const boostId = boostIdElement.innerText;

    $.ajax({
        url: '/boost/buy',
        method: 'post',
        dataType: 'json',
        data: { boostId: boostId },
        success: (response) => onBuyBoostSuccess(response, boostButton),
    });
}

function onBuyBoostSuccess(response, boostButton) {
    const score = response["score"];

    const boostPriceElement = boostButton.getElementsByClassName("boost-price")[0];
    const boostQuantityElement = boostButton.getElementsByClassName("boost-quantity")[0];
    //const multRedZoneElement = boostButton.getElementsByClassName("boost_mult")[0];

    const boostPrice = Number(response["price"]);
    const boostQuantity = Number(response["quantity"]);
    //const boostMult = Number(response["boost_mult"]);

    boostPriceElement.innerText = boostPrice;
    boostQuantityElement.innerText = boostQuantity;
    //multRedZoneElement.innerText = boostMult;

    updateScoreFromApi(score);
}

function addSecond() {
    seconds++;

    if (seconds >= threshold) {
        addPointsToScore();
    }

    if (seconds > 0) {
        addPointsFromSecond();
    }
}

function click(isClickRedZone) {
    clicks++; // Общее количество кликов

    if (isClickRedZone) {
        clicksOnRedZone++; // Увеличиваем количество кликов по красной зоне
        addPointsFromClickMult(); // Начисляем очки с множителем
    } else {
        clicksOnMap++; // Увеличиваем количество кликов по обычной карте
        addPointsFromClick(); // Начисляем стандартные очки
    }

    if (clicks >= threshold) {
        addPointsToScore(); // Отправляем очки на сервер при достижении порога
    }
}

function updateUiScore() {
    currentScoreElement.innerText = currentScore;
    recordScoreElement.innerText = recordScore;
    profitPerClickElement.innerText = profitPerClick;
    profitPerSecondElement.innerText = profitPerSecond;
    //multRedZoneElement.innerText = multRedZone;

    toggleBoostsAvailability();
}


function addPointsFromClick() {
    const points = profitPerClick;
    currentScore += points;
    recordScore += points;

    updateUiScore(); // Обновляем интерфейс
}

function addPointsFromClickMult() {
    const points = profitPerClick * multRedZone;
    currentScore += points;
    recordScore += points;

    updateUiScore(); // Обновляем интерфейс
}


function addPointsFromSecond() {
    currentScore += profitPerSecond;
    recordScore += profitPerSecond;

    updateUiScore();
}

function addPointsToScore() {
    $.ajax({
        url: '/score',
        method: 'post',
        dataType: 'json',
        data: {
            seconds: seconds,
            clicksOnMap: clicksOnMap,        // Отправляем количество кликов по карте
            clicksOnRedZone: clicksOnRedZone // Отправляем количество кликов по красной зоне
        },
        success: (response) => onAddPointsSuccess(response),
    });
}

function onAddPointsSuccess(response) {
    seconds = 0;
    clicks = 0;
    clicksOnRedZone = 0
    clicksOnMap = 0

    updateScoreFromApi(response);
}
function updateScoreFromApi(scoreData) {
    currentScore = Number(scoreData["currentScore"]);
    recordScore = Number(scoreData["recordScore"]);
    profitPerClick = Number(scoreData["profitPerClick"]);
    profitPerSecond = Number(scoreData["profitPerSecond"]);
    //multRedZone = Number(scoreData["MultRedZone"]);

    updateUiScore();
}

function toggleBoostsAvailability() {
    const boostButtons = document.getElementsByClassName("boost-button");

    for (let i = 0; i < boostButtons.length; i++) {
        const boostButton = boostButtons[i];

        const boostPriceElement = boostButton.getElementsByClassName("boost-price")[0];
        const boostPrice = Number(boostPriceElement.innerText);

        if (boostPrice > currentScore) {
            boostButton.disabled = true;
            continue;
        }

        boostButton.disabled = false;
    }
}
