# HOW TO SETUP THE CODEBASE AND RUN THE TEST SUITE

## Requirement
- To run the PoCs you need to have Foundry installed
- To run the invariant tests you to have Echidna or Medusa installed

## Clone this repo
```
git clone https://github.com/Renzo1/Elfi-Foundry2.git
```

## Install dependencies
Install XXX
```
forge install

forge install Recon-Fuzz/chimera --no-commit
```

## Echidna Fuzz Command
```
    echidna . --contract CryticTester --config echidna.yaml
```

## Medusa Fuzz Command
```
    medusa fuzz
```

## Run PoC
```
    forge test --match-test TEST_NAME
```
Example:
```
    forge test --match-test testDemo
```