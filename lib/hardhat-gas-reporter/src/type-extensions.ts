import "hardhat/types/config";

import { EthGasReporterConfig } from "./types";

declare module "hardhat/types/config" {
  interface HardhatUserConfig {
    gasReporter?: Partial<EthGasReporterConfig>;
  }
}
