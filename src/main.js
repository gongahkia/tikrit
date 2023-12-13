alert("tikrit begins");

// ---------- LEGEND ----------

// . => floor tiles
// @ => player (white), when dodge rolling become light gray
// X => solid wall indoor outdoor (yellow, dark gray or brown)
// [#, ¥] => trees (dark green)
// [~, ] => water
// = => bridge over gap or spikes or water (brown)
// ^ => spikes
// [",',`] => grass (mixes of bright and dark green)
// [+, -] => open door, closed door
// [Ø, Ö]  => locked door, cave entrance
// & => health pickup
// ! => weapon pickup
// % => item pickup
// ? => mystery chest
// ê => boss
// M => enemy mob
// R => enemy rampager
// S => enemy sniper
// B => enemy bomber

// !! DONT RENDER AIR BLOCK IN ACTUAL RENDER ENGINE (?) !!

// ---------- UTIL FUNCTIONS ----------

function checkBounds(entity) {
  return entity.player.coord.x < 0 || entity.player.coord.y < 0 || entity.player.coord.y > c1.height - entity.player.size || entity.player.coord.x > c1.width - entity.player.size;
}

// ---------- CANVAS ----------

// instantiating canvas
const c1 = document.getElementById("c1");

// dynamically resizes canvas
/* 
c1.width = window.innerWidth;
c1.height = window.innerHeight;
*/

c1.width = 700;
c1.height = 700;

console.log(c1);
const c = c1.getContext("2d");
c.font = "20px 'Comic Sans MS', cursive";

// ---------- PREP WORK ----------

// FUA add each rendering model to a dictionary

// ----- WORLD OBJECTS -----

// ----- ENTITIES ----- 

var entity = {
  player: {
    size: 20,
    coord: {
      x:0,
      y:0
    },
    speed: 20,
    health: 10,
    items: {

    },
    weight: 0, // calculated based on number of items, affects speed proportionally FUA add function to calculate speed
    currently_dodge_rolling: false
  }

}

// ---------- ACTUAL CODE ------------

// ---------- USER INPUT ----------

// movement => "wasd"
// dodge roll one square in that direction; you are invincible during the roll like in dead cells => 'shift' + "wasd"
// close door => 'c'
// use item => 'u'
// drop item => 'd'
// throw item => 't'
// pause game => 'space'
// quit game and save => 'Q'

// FUA might have to debug this further
document.addEventListener('keydown', function(event) {
  if (['w', 'a', 's', 'd', 'W', 'A', 'S', 'D', 'c', 'u', 'd', 't', 'Q', ' '].includes(event.key) || event.key === 'Spacebar') {
    console.log(event.keycode);
    switch (event.key) {
      case 'w':
        entity.player.coord.y -= entity.player.speed;
        if (checkBounds(entity)) {
          entity.player.coord.y += entity.player.speed;
        } else {}
        break;
      case 'a':
        entity.player.coord.x -= entity.player.speed;
        if (checkBounds(entity)) {
          entity.player.coord.x += entity.player.speed;
        } else {}
        break;
      case 's':
        entity.player.coord.y += entity.player.speed;
        if (checkBounds(entity)) {
          entity.player.coord.y -= entity.player.speed;
        } else {}
        break;
      case 'd':
        entity.player.coord.x += entity.player.speed;
        if (checkBounds(entity)) {
          entity.player.coord.x -= entity.player.speed;
        } else {}
        break;
      // FUA ADD ACTIONS FOR OTHER THINGS AS BELOW
      case 'W':
        break;
      case 'A':
        break;
      case 'S':
        break;
      case 'D':
        break;
      case 'c':
        break;
      case 'u':
        break;
      case 'd':
        break;
      case 't':
        break;
      case 'Q':
        break;
      case ' ':
        break;
      default:
        if (event.key === 'Spacebar') {
          // FUA add something here also
        } else {
          console.log(`Invalid input detected. Keypress was ${event.key}`)
        }
    }
  }
});

// ---------- EVENT LOOP ----------
function eventLoop() {
  c.clearRect(0, 0, c1.width, c1.height);
  c.fillText("@", entity.player.coord.x, entity.player.coord.y + entity.player.size);
  requestAnimationFrame(eventLoop);
}

requestAnimationFrame(eventLoop);