using Godot;
using System;

// ------------ DELETE NODES ----------
	// QueueFree() deletes available nodes

// ---------- SIGNAL ----------
	// when something occurs to a node in godot, it emits a signal (same as events in JS)

public class bullet : Node2D {

	public float travelRadius = 400; // px

	private float distanceTravelled = 0; // px

	public override void _Ready() {
		var area = GetNode<Area2D>("Area2D");
		area.Connect("area_entered", this, "OnCollision"); // .Connect() connects a method to a node
		area.Connect("body_entered", this, "OnCollision");
	}

	public override void _Process(float delta) {

		float speed = 400;
		float distanceMoved = speed * delta; // determine how far an object should move regardless of the frame rate of the player screen => in pixels
		Position += Transform.x.Normalized() * distanceMoved;
		distanceTravelled += distanceMoved;

		if (distanceTravelled > travelRadius) {
			GD.Print("Bullet despawning out of range");
			QueueFree();
		}
	}

	private void OnCollision(Node with) {
		GD.Print("Bullet hit another collision object!"); // prints to the console similar to Console.Write();
		QueueFree(); // removes bullet node from scene
	}
}
