"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.printTransformDependencies = void 0;
var _dependenciesAddGenerated = require("./dependenciesAdd.generated.js");
var _dependenciesMatrixGenerated = require("./dependenciesMatrix.generated.js");
var _dependenciesTypedGenerated = require("./dependenciesTyped.generated.js");
var _dependenciesZerosGenerated = require("./dependenciesZeros.generated.js");
var _factoriesAny = require("../../factoriesAny.js");
/**
 * THIS FILE IS AUTO-GENERATED
 * DON'T MAKE CHANGES HERE
 */

var printTransformDependencies = {
  addDependencies: _dependenciesAddGenerated.addDependencies,
  matrixDependencies: _dependenciesMatrixGenerated.matrixDependencies,
  typedDependencies: _dependenciesTypedGenerated.typedDependencies,
  zerosDependencies: _dependenciesZerosGenerated.zerosDependencies,
  createPrintTransform: _factoriesAny.createPrintTransform
};
exports.printTransformDependencies = printTransformDependencies;