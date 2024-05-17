import { factory } from '../../utils/factory.js';
var name = 'corr';
var dependencies = ['typed', 'matrix', 'mean', 'sqrt', 'sum', 'add', 'subtract', 'multiply', 'pow', 'divide'];
export var createCorr = /* #__PURE__ */factory(name, dependencies, _ref => {
  var {
    typed,
    matrix,
    sqrt,
    sum,
    add,
    subtract,
    multiply,
    pow,
    divide
  } = _ref;
  /**
   * Compute the correlation coefficient of a two list with values, For matrices, the matrix correlation coefficient is calculated.
   *
   * Syntax:
   *
   *     math.corr(A, B)
   *
   * Examples:
   *
   *     math.corr([1, 2, 3, 4, 5], [4, 5, 6, 7, 8])     // returns 1
   *     math.corr([1, 2.2, 3, 4.8, 5], [4, 5.3, 6.6, 7, 8])     // returns 0.9569941688503644
   *     math.corr(math.matrix([[1, 2.2, 3, 4.8, 5], [1, 2, 3, 4, 5]]), math.matrix([[4, 5.3, 6.6, 7, 8], [1, 2, 3, 4, 5]])) // returns DenseMatrix [0.9569941688503644, 1]
   *
   * See also:
   *
   *     median, mean, min, max, sum, prod, std, variance
   *
   * @param {Array | Matrix} A The first array or matrix to compute correlation coefficient
   * @param {Array | Matrix} B The second array or matrix to compute correlation coefficient
   * @return {*} The correlation coefficient
   */
  return typed(name, {
    'Array, Array': function ArrayArray(A, B) {
      return _corr(A, B);
    },
    'Matrix, Matrix': function MatrixMatrix(xMatrix, yMatrix) {
      return matrix(_corr(xMatrix.toArray(), yMatrix.toArray()));
    }
  });
  /**
   * Calculate the correlation coefficient between two arrays or matrices.
   * @param {Array | Matrix} A
   * @param {Array | Matrix} B
   * @return {*} correlation coefficient
   * @private
   */
  function _corr(A, B) {
    if (Array.isArray(A[0]) && Array.isArray(B[0])) {
      var correlations = [];
      for (var i = 0; i < A.length; i++) {
        correlations.push(correlation(A[i], B[i]));
      }
      return correlations;
    } else {
      return correlation(A, B);
    }
  }
  function correlation(A, B) {
    var n = A.length;
    var sumX = sum(A);
    var sumY = sum(B);
    var sumXY = A.reduce((acc, x, index) => add(acc, multiply(x, B[index])), 0);
    var sumXSquare = sum(A.map(x => pow(x, 2)));
    var sumYSquare = sum(B.map(y => pow(y, 2)));
    var numerator = subtract(multiply(n, sumXY), multiply(sumX, sumY));
    var denominator = sqrt(multiply(subtract(multiply(n, sumXSquare), pow(sumX, 2)), subtract(multiply(n, sumYSquare), pow(sumY, 2))));
    return divide(numerator, denominator);
  }
});