alert("tikrit begins");

// ---------- LEGEND ----------

// . => air block
// @ => player (white)
// X => solid wall indoor outdoor (grey)
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

// !! DONT RENDER AIR BLOCK IN ACTUAL RENDER ENGINE !!

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

// ---------- PREP WORK ----------

const keys = {
  w: false,
  a: false,
  s: false,
  d: false,
};

// FUA add each rendering model to a dictionary

// ----- WORLD OBJECTS -----

// ----- ENTITIES ----- 

// ---------- ACTUAL CODE ------------

// ---------- USER INPUT ----------

// ---------- EVENT LOOP ----------
c.font = "20px 'Comic Sans MS', cursive";
c.fillText("@",10,30);