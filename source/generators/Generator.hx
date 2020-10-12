package generators;

import flixel.FlxG;

/**
 * Generator containing some methods for generating `matrix`es of `Int`s.
 *
 * Check method descriptions for a more comprehensive explanation.
 */
class Generator {
	/**
	 * The number of tiles in width that the generated level will have.
	 */
	var levelWidth:Int;

	/**
	 * The number of tiles in height that the generated level will have.
	 */
	var levelHeight:Int;

	/**
	 * The number of neighbours that induces a cell to die(turn to a 0) of starvation during a simulation step.
	 */
	var deathLimit:Int;

	/**
	 * The number of neighbours that induces a cell to be born (turn to a 1) during a simulation step.
	 */
	var birthLimit:Int;

	/**
	 * Instantiate a new generator, specifying the default width and height of the levels it will generate.
	 *
	 * Both can be overridden when generating a level thanks to optional arguments.
	 * @param _levelWidth the number of tiles/cells in width that the generated level will have.
	 * @param _levelHeight the number of tiles/cells in height that the generated level will have.
	 */
	public function new(_levelWidth:Int, _levelHeight:Int) {
		levelWidth = _levelWidth;
		levelHeight = _levelHeight;
	}

	/**
	 * Generates a matrix of 0s and applies to each of them a chance of turning alive.
	 *
	 * @param aliveChance the chance that a cell will turn alive
	 * @return a tilemap of type `Array<Array<Int>>` where each cell can assume `Int` values
	 */
	public function generateRandom(aliveChance:Float, ?_levelWidth:Int, ?_levelHeight:Int):Array<Array<Int>> {
		if (_levelWidth != null)
			levelWidth = _levelWidth;
		if (_levelHeight != null)
			levelHeight = _levelHeight;

		// fill the matrix with 1s according to the width and height
		var levelData:Array<Array<Int>> = [for (x in 0...levelWidth) [for (y in 0...levelHeight) 0]];

		// apply random chance to turn to 1 to each tile
		for (x in 0...levelWidth) {
			for (y in 0...levelHeight) {
				if (FlxG.random.float(0, 1) < aliveChance) {
					levelData[x][y] = 1;
				}
			}
		}

		return levelData;
	}

	/**
	 * Places the player in one of the empty tiles of the level that's passed in.
	 * @param _levelData the level we want to place the player in.
	 * @return returns the modified `_levelData` that was passed in.
	 */
	function placePlayer(_levelData:Array<Array<Int>>):Array<Array<Int>> {
		var playerPlaced = false;

		for (x in 0...levelWidth) {
			for (y in 0...levelHeight) {
				if (!playerPlaced) {
					if (_levelData[x][y] == 0) {
						_levelData[x][y] = 3;
						playerPlaced = true;
					}
				}
			}
		}

		return _levelData;
	}

	function generateIsland(?_levelWidth:Int, ?_levelHeight:Int):Array<Array<Int>> {
		if (_levelWidth != null)
			levelWidth = _levelWidth;
		if (_levelHeight != null)
			levelHeight = _levelHeight;

		// we fill the matrix with 0s according to the width and height
		var levelData:Array<Array<Int>> = [for (x in 0...levelWidth) [for (y in 0...levelHeight) 0]];

		return levelData;
	}

	/**
	 * Generates a matrix that will be used to generate the game world using a cellular automaton.
	 *
	 * Tweak the parameters to obtain different results, although it should generally resemble a cave.
	 *
	 * @param _aliveChance = 0.4 the probability that a cell will start out alive
	 * @param _deathLimit = 3 the minimum number of neighbours needed kill a cell
	 * @param _birthLimit = 4 the minimum number of neighbours needed to make a cell alive
	 * @param _overcrowdLimit = 6 the maximum number of neighbours that a cell can have without dying
	 * @param _stepNumber = 50 the default number of steps of simulation we run - generally the higher the smoother
	 * @param ?_levelWidth if specified overrides the width that was given to the `Generator` on creation
	 * @param ?_levelHeight if specified overrides the height that was given to the `Generator` on creation
	 * @return a matrix of `Int`s that's hopefully similar in shape to a cave
	 */
	public function generateCave(_aliveChance = 0.4, _deathLimit = 3, _birthLimit = 4, _stepNumber = 2, ?_levelWidth:Int,
			?_levelHeight:Int):Array<Array<Int>> {
		// if new dimensions were passed in we modify them
		if (_levelWidth != null)
			levelWidth = _levelWidth;
		if (_levelHeight != null)
			levelHeight = _levelHeight;

		// we create a new matrix and fill it with 0s according to the width and height
		var levelData:Array<Array<Int>> = [for (x in 0...levelWidth) [for (y in 0...levelHeight) 0]];

		// fill the matrix with random values
		levelData = generateRandom(_aliveChance);
		// run the cellular automaton for a set number of steps
		for (i in 0..._stepNumber) {
			levelData = doStep(levelData);
		}

		levelData = placePlayer(levelData);

		return levelData;
	}

	/**
	 * Returns the number of cells around the one provided that are currently alive.
	 *
	 * We also check diagonals, so a max of 8 (cells) can be returned.
	 *
	 * @param _levelData the level where you want to count the neighbours in
	 * @param _cellX the X coordinate of the cell you want to count the neighbours of
	 * @param _cellY the Y coordinate of the cell you want to count the neighbours of
	 * @return the number of 1s or alive neighbours that the specified cell has in that level
	 */
	function countAliveNeighbours(_levelData:Array<Array<Int>>, _cellX:Int, _cellY:Int):Int {
		var count:Int = 0;

		// to count neighbours we'll check cells that are at the supplied x-1 and x+1
		for (x in -1...2) {
			// to count neighbours we'll check cells that are at the supplied y-1 and y+1
			for (y in -1...2) {
				var neighX = _cellX + x;
				var neighY = _cellY + y;

				// if looking at ourselves
				if (neighX == _cellX && neighY == _cellY) { // do nothing
				} else if (neighX < 0 || neighY < 0 || neighX >= _levelData.length || neighY >= _levelData[0].length) {
					count++; // if the cell is out of the map we count it as solid (useful to fill in edges of caves)
				} else if (_levelData[neighX][neighY] == 1) {
					count++; // if the cell is a 1 it's solid so we count it
				}
			}
		}
		return count;
	}

	/**
	 * Applies the cellular automaton rules for a step of the simlation.
	 *
	 * uof overpopulationChange `overcrowdLimit` and `birthLimit` to change how many cells die or are born.
	 *
	 * @param _previousLevel the current map to which you want to apply the simulation step
	 * @return a new level that has undergone the simulation
	 */
	function doStep(_previousLevel:Array<Array<Int>>):Array<Array<Int>> {
		// if we modify the same matrix we read from the generation will mess up, so here we instantiate our new, modified level
		var newLevel:Array<Array<Int>> = [for (x in 0...levelWidth) [for (y in 0...levelHeight) 0]];

		// we loop over the level that was passed in
		for (x in 0...levelWidth) {
			for (y in 0...levelHeight) {
				// we count the neighbours of each cell
				var neighCount = countAliveNeighbours(_previousLevel, x, y);

				if (_previousLevel[x][y] == 1) { // If a cell is alive
					if (neighCount < deathLimit) { // and has too few neighbours
						newLevel[x][y] = 0; // copy it to the new level as dead
					} else {
						newLevel[x][y] = 1; // copy it to the new level as alive
					}
				} else if (_previousLevel[x][y] == 0) { // if the cell is dead
					if (neighCount > birthLimit) { // and has enough neighbours to be born
						newLevel[x][y] = 1; // copy it to the new level as alive
					} else {
						newLevel[x][y] = 0; // copy it to the new level as dead
					}
				}
			}
		}

		return newLevel;
	}
}