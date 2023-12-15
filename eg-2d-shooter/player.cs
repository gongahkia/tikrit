using Godot;
using System;

public class player : Node2D {

// ---------- _PROCESS ----------
	// POSITION => instance attribute which affects the position of the player node
	// ROTATION => instance attribute which affects the rotation of the player node
	// READY => constructor method for entities in a given scene
	// method called every frame during the processing of the game loop
	// allows for updating of game logic continuously
	// commonly used for player input, character movement, realtime interactions
	// call the float delta parameter whenever we need to calculate timing-related things from when the last time _Process was called
		// makes movement consistent across different hardware

	PackedScene bullets; 

	public override void _Ready() {
		bullets = GD.Load<PackedScene>("res://bullet.tscn"); // PackedScene helps us link 2 scenes together via their file path
	}

	public override void _Process(float delta) { // parameter delta tracks time whenever the _process method is called

		// MOVE IN RESPONSE TO ARROW KEYS

		float speed = 200; // pixels per second
		float moveAmount = speed * delta;
		Vector2 moveVector = new Vector2(0,0);
		if (Input.IsKeyPressed((int)KeyList.W) || Input.IsKeyPressed((int)KeyList.Up)){
			moveVector.y = -1;
		}
		if (Input.IsKeyPressed((int)KeyList.S) || Input.IsKeyPressed((int)KeyList.Down)){
			moveVector.y = 1;
		}
		if (Input.IsKeyPressed((int)KeyList.A) || Input.IsKeyPressed((int)KeyList.Left)){
			moveVector.x = -1;
		}
		if (Input.IsKeyPressed((int)KeyList.D) || Input.IsKeyPressed((int)KeyList.Right)){
			moveVector.x = 1;
		}
		Position += moveVector.Normalized() * moveAmount; // .Normalized() method ensures a vector always has a length of 1

		// MOVE IN RESPONSE TO MOUSE MOVEMENT
		Rotation = (GetGlobalMousePosition() - GlobalPosition).Angle();
	}

	public override void _UnhandledInput(InputEvent @event) {
		if (@event is InputEventMouseButton mouseEvent) {
			if (mouseEvent.ButtonIndex == (int)ButtonList.Left && mouseEvent.Pressed) {
				GD.Print("Player clicked mouse");
				bullet bullet = (bullet)bullets.Instance();
				bullet.Position = Position; // bullet object takes on the position and rotation of the player upon instantiation
				bullet.Rotation = Rotation;
				GetParent().AddChild(bullet);
				GetTree().SetInputAsHandled();
			}
		}
	}
}
