alert("tikrit begins");

// ---------- LEGEND ----------
// . => air block
// P => player
// B => block
// E => enemy
// I => item 

// ---------- CANVAS ----------

// instantiating canvas
const c1 = document.getElementById("c1");
c1.width = window.innerWidth;
c1.height = window.innerHeight;
console.log(c1);
const c = c1.getContext("2d");

// half-screen size => 798 width, 789 height
// full-screen size => 1600 width,  789 height

// ---------- PREP WORK ----------

const keys = {
  w: false,
  a: false,
  s: false,
  d: false,
};

// ----- WORLD OBJECTS -----

const world = {

  ui: {

    char: {
      // rendering defaults
      spriteSrc: "", // FUA add here
      srcX: 0,
      srcY: 0,
      srcWidth: 32, // FUA EDIT ACCORDINGLY
      srcHeight: 32,
      destWidth: 32,
      destHeight: 32,

      // character information
      destX: 0, // FUA EDIT ACCORDINGLY, probably need a function to generate coordinates iteratively
      destY: 0,
    }

  },

  object: {

    block: {
      // rendering defaults
      spriteSrc: "", // FUA add here
      srcX: 0,
      srcY: 0,
      srcWidth: 32, // FUA EDIT ACCORDINGLY
      srcHeight: 32,
      destWidth: 32,
      destHeight: 32,

      // coord array 2 be rendered
      coord: [
        {destX:0, destY:5},
        {destX:2, destY:10} // FUA ADD STUFF HERE but make this update dynamically by reading a text file
      ]

    },

    item : {

      healthPickup: {
        // rendering defaults
        spriteSrc: "", // FUA add here
        srcX: 0,
        srcY: 0,
        srcWidth: 32, // FUA EDIT ACCORDINGLY
        srcHeight: 32,
        destWidth: 32,
        destHeight: 32,

        // coord array 2 be rendered
        coord: [
          // can be empty if no items
        ]
      },

      weaponPickup: {
        // rendering defaults
        spriteSrc: "", // FUA add here
        srcX: 0,
        srcY: 0,
        srcWidth: 32, // FUA EDIT ACCORDINGLY
        srcHeight: 32,
        destWidth: 32,
        destHeight: 32,

        // coord array 2 be rendered
        coord: [
          // can be empty if no items
        ]
      },

      speedPickup: {
        // rendering defaults
        spriteSrc: "", // FUA add here
        srcX: 0,
        srcY: 0,
        srcWidth: 32, // FUA EDIT ACCORDINGLY
        srcHeight: 32,
        destWidth: 32,
        destHeight: 32,

        // coord array 2 be rendered
        coord: [
          // can be empty if no items
        ]
      },

    }

  },

// ----- ENTITIES ----- 

// ---------- ACTUAL CODE ------------

// ---------- USER INPUT ----------

// ---------- EVENT LOOP ----------