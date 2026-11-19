package biz.dfch.specmgrdemo.app;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

/**
 * The main class of the backend (feat-9-walking-skeleton, Phase 200, Task 200.110). It starts the web service
 * (the embedded Tomcat of spring-boot-starter-web), and the service gives the two operations of the contract
 * (the generated interfaces of the package biz.dfch.specmgrdemo.api): the operation GET /status (REQ
 * 1ca335d7-969a-443e-9392-165fdeea99a0) and the operation GET /info (REQ
 * 271168a4-2a6f-40a1-b277-89711b18a087).
 *
 * <p>The component scan starts in the base package biz.dfch.specmgrdemo, so it finds the beans of this package
 * (the controllers, the configuration and the filter) and not a bean of the generated packages (the interface
 * of the package api has no bean, and the class of the package model has no bean).
 */
@SpringBootApplication
public class SpecMgrDemoApplication {

  /**
   * Start the service with the arguments of the command line.
   *
   * @param args the arguments of the command line
   */
  public static void main(String[] args) {
    SpringApplication.run(SpecMgrDemoApplication.class, args);
  }
}
