// FUA
	// add the idling animation

using Godot;
using System;

public partial class Area2D : Godot.Area2D
{
 private AnimatedSprite _animatedSprite;

	public override void _Ready()
	{
		_animatedSprite = GetNode<AnimatedSprite>("AnimatedSprite");
	}

	public override void _Process(float delta)
	{
		
		float speed = 200; // pixels per second
		float moveAmount = speed * delta;
		Vector2 moveVector = new Vector2(0,0);
		if (Input.IsKeyPressed((int)KeyList.W) || Input.IsKeyPressed((int)KeyList.Up)){
			moveVector.y = -1;
			Scale = new Vector2(1, 1);
			_animatedSprite.Play("run");
		}
		else if (Input.IsKeyPressed((int)KeyList.S) || Input.IsKeyPressed((int)KeyList.Down)){
			moveVector.y = 1;
			Scale = new Vector2(1, 1);
			_animatedSprite.Play("run");
		}
		else if (Input.IsKeyPressed((int)KeyList.A) || Input.IsKeyPressed((int)KeyList.Left)){
			moveVector.x = -1;
			Scale = new Vector2(-1, 1);
			_animatedSprite.Play("run");
		}
		else if (Input.IsKeyPressed((int)KeyList.D) || Input.IsKeyPressed((int)KeyList.Right)){
			moveVector.x = 1;
			Scale = new Vector2(1, 1);
			_animatedSprite.Play("run");
		}
		else {
			_animatedSprite.Stop();
		}

		Position += moveVector.Normalized() * moveAmount; // .Normalized() method ensures a vector always has a length of 1

	}
}
