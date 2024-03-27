locals {
  default_custom_domains_concretego = {
    e2e = ["e2e.concretego.com", "e2e.cg.sysdyne.cloud"]
    production = ["*.concretego.com", "*.cg.sysdyne.cloud", "cg.sysdyne.cloud", "concretego.com"]
  }
  
  default_custom_domains_concretego_api = {
    e2e = ["api-e2e.concretego.com"]
    production = ["*.concretego.com"]
  }

  concretego_ssl_thumbprint = "43405768AD6F1B433BE2AE1B772A39C1837BFD41"
  cg_sysdyne_cloud_ssl_thumbprint = "9ECBE21BDEC54E7B4965D37C4B9949DFCE15BE2A"
  
}