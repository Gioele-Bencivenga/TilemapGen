package entities;

import hxmath.math.Vector2;
import flixel.FlxG;
import utilities.JoFuncs;
import brains.Perceptron;
import hxmath.math.MathUtil;
import flixel.FlxSprite;
import supplies.Supply;
import haxe.Resource;

using utilities.FlxEcho;

/**
 * Autonomous Entity class representing an entity able to act autonomously by acquiring targets and moving towards them.
 */
class AutoEntity extends Entity {
	/**
	 * The entity's "brain", represented by a `Perceptron` class.
	 */
	var brain(default, null):Perceptron;

	/**
	 * The current `Supply` an entity wants to reach. Can be set using `assignTarget()`.
	 */
	var target(default, null):Supply;

	public function new(_x:Float, _y:Float, _width:Int, _height:Int, _color:Int) {
		super(_x, _y, _width, _height, _color);

		brain = new Perceptron(2);
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		if (target != null) {
			// seekTarget(300);
			brainSeek();
		}
	}

	public function assignTarget(_target:Supply) {
		target = _target;
	}

	function brainSeek(_targets:Array<Supply> = null) {
		if(_targets == null)
			_targets = [target];

		// initialise an array of forces (vectors) as long as the number of targets
		var forces = [for (i in 0..._targets.length) new Vector2(0, 0)];

		for (i in 0...forces.length) {
			forces[i] = seekTarget(_targets[i]);
		}

		// calculate where we want to go
		var result = brain.feedForward(forces);
		desiredDirection = result;

		// learn from our error (distance from target)
		var error = target.get_body().get_position() - this.get_body().get_position();
		brain.train(forces, error);
	}

	/**
	 * Points the `desiredDirection` vector towards the `target` with a length of `maxSpeed` or less. The movement handling method in `Entity` will then move the entity in the `desiredDirection`.
	 * @param _target if you want you can specify a different target from `target` to follow, otherwise this will get set = to `target` if left as `null`
	 * @param _arriveDistance 0 by default, set it to the distance after which the entity must start slowing down (higher = further)
	 */
	function seekTarget(_target:Supply = null, _arriveDistance = 0) {
		// if no _target has been provided we use the default target
		if (_target == null)
			_target = target;

		// subtracting the target position vector from the entity's position vector gives us a vector pointing from us to the target
		desiredDirection = _target.get_body().get_position() - this.get_body().get_position();

		var distance = desiredDirection.length; // we use the vector's length to measure the distance
		// if _arriveDistance was set higher than 0 and the measured distance is less than it
		if (distance < _arriveDistance) {
			// we create a new speed variable that diminishes in value with how close we are
			var newSpeed = JoFuncs.map(distance, 0, _arriveDistance, 0, maxSpeed);
			desiredDirection.normalizeTo(newSpeed); // and proceed at the lower speed
		} else {
			desiredDirection.normalizeTo(maxSpeed); // otherwise we proceed at maxSpeed
		}

		return desiredDirection;
	}

	/**
	 * Points the `desiredDirection` vector opposite to the `target` with a length of `maxSpeed` or less. The movement handling method in `Entity` will then move the entity in the `desiredDirection`.
	 *
	 * This is exactly the opposite of `seekTarget()`.
	 * @param _target if you want you can specify a different target from `target` to flee from, otherwise this will get set = to `target` if left as `null`
	 * @param _departDistance 0 by default, set it to the distance after which the entity must start fleeing the target (higher = further)
	 */
	function fleeTarget(_target:Supply = null, _departDistance:Float = 0) {
		// if no _target has been provided we use the default target
		if (_target == null)
			_target = target;

		// subtracting the target position vector from the entity's position vector gives us a vector pointing from us to the target
		desiredDirection = _target.get_body().get_position() - this.get_body().get_position();
		// we invert the vector so it points opposite
		desiredDirection.multiplyWith(-1);

		var distance = desiredDirection.length; // we use the vector's length to measure the distance
		// if _departDistance was set higher than 0 and the measured distance is less than it
		if (distance < _departDistance) {
			// we create a new speed variable that increases in value with how close we are
			var newSpeed = JoFuncs.map(distance, 0, _departDistance, maxSpeed, 0);
			desiredDirection.normalizeTo(newSpeed); // and proceed at the lower speed
		} else {
			desiredDirection.normalizeTo(0); // otherwise we stay put
		}
	}
}
