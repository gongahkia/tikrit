using Godot;
using System;

public class player : Node2D
{

// ---------- _PROCESS ----------
	// method called every frame during the processing of the game loop
	// allows for updating of game logic continuously
	// commonly used for player input, character movement, realtime interactions
	// call the float delta parameter whenever we need to calculate timing-related things from when the last time _Process was called
		// makes movement consistent across different hardware

	public override void _Process(float delta) { // parameter delta tracks time whenever the _process method is called

		// MOVE IN RESPONSE TO ARROW KEYS

		float speed = 200; // pixels per second
		float moveAmount = speed * delta;

		Vector2 moveVector = new Vector2(0,0);

		if (Input.IsKeyPressed((int)KeyList.Up)){
			moveVector.y = -moveAmount;
		}
		if (Input.IsKeyPressed((int)KeyList.Down)){
			moveVector.y = moveAmount;
		}
		if (Input.IsKeyPressed((int)KeyList.Left)){
			moveVector.x = -moveAmount;
		}
		if (Input.IsKeyPressed((int)KeyList.Right)){
			moveVector.x = moveAmount;
		}

		Position += moveVector;

		// PLAYER ALWAYS FACES THE MOUSE
		
		Rotation = (GetGlobalMousePosition() - GlobalPosition).Angle();
	}
}
