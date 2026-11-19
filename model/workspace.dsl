workspace "SpecMgrDemo" "The architecture model of the project (DEC b6e8808f-86b4-41a4-92f2-33d38869beed and DEC e85e9685-0787-4dff-9ee5-9d46670e9ee4). The code must obey this model." {

    !impliedRelationships false

    model {
        system = softwareSystem "SpecMgrDemo" "The status API of the project: the backend (the Maven module) and the frontend (the pnpm module)." {
            perspectives {
                "Evolution" "The components of feat-9-walking-skeleton join the model when that feature merges (Phase 120 of feat-50-structurizr-model-rules)." "Medium"
            }

            backend = container "backend" "The Maven module of the backend: the generated Spring server interfaces and the generated model classes." "Java 21 (Maven)" {
                properties {
                    "code.language" "java"
                    "code.root" "biz.dfch.specmgrdemo"
                }
                perspectives {
                    "Security" "The module gives the status API of the project. The endpoint gives no sensitive data." "Low"
                }

                api = component "api" "The generated Spring server interfaces (the top-level package biz.dfch.specmgrdemo.api)." "Java interface" {
                    properties {
                        "code.language" "java"
                        "code.package" "biz.dfch.specmgrdemo.api"
                        "code.allowedExternal" "org.springframework.., jakarta.validation.., jakarta.annotation"
                        "specmgr-refs" "REQ 1ca335d7-969a-443e-9392-165fdeea99a0"
                    }
                }

                model = component "model" "The generated model classes (the top-level package biz.dfch.specmgrdemo.model)." "Java class" {
                    properties {
                        "code.language" "java"
                        "code.package" "biz.dfch.specmgrdemo.model"
                        "code.allowedExternal" "com.fasterxml.jackson.., org.springframework.., jakarta.validation.., jakarta.annotation"
                    }
                }

                api -> model "The interfaces of api reference the classes of model"
            }

            frontend = container "frontend" "The pnpm module of the frontend: the generated TypeScript types and the generated Zod schemas." "TypeScript (pnpm)" {
                properties {
                    "code.language" "typescript"
                }
                perspectives {
                    "Security" "The module consumes the status API of the backend. It gives no data of the user." "Low"
                }

                types = component "types" "The generated TypeScript types (the unit types, the folder frontend/src/generated/types)." "TypeScript" {
                    properties {
                        "code.language" "typescript"
                        "code.path" "src/generated/types/**"
                    }
                }

                zod = component "zod" "The generated Zod schemas (the unit zod, the folder frontend/src/generated/zod)." "TypeScript" {
                    properties {
                        "code.language" "typescript"
                        "code.path" "src/generated/zod/**"
                        "code.allowedExternal" "zod"
                    }
                }

                test = component "test" "The tests of the module (the unit test, the folder frontend/src/test)." "TypeScript" {
                    properties {
                        "code.language" "typescript"
                        "code.path" "src/test/**"
                        "code.allowedExternal" "vitest, fast-check"
                    }
                }

                root = component "root" "The files that lie directly in frontend/src (the unit root, today frontend/src/mutation-example.ts)." "TypeScript" {
                    properties {
                        "code.language" "typescript"
                        "code.path" "src/mutation-example.ts"
                    }
                }

                test -> zod "The tests import the generated Zod schemas"
                test -> root "The tests import the example file of frontend/src"
            }

            frontend -> backend "The frontend consumes the API of the backend"
        }

        environment = deploymentEnvironment "The environment" {
            host = deploymentNode "host" "The single host of the model (the deployment unit of the model; this feature adds no infrastructure)." "Linux (the machine of the owner)"
            host -> backend
            host -> frontend
        }
    }

    views {
        context = systemContext system "Context" "The context of the system (the viewpoint context of Rozanski & Woods)." {
            include *
            autolayout
            properties {
                "rw.viewpoint" "context"
            }
        }

        functional = container system "Functional" "The containers of the system (the viewpoint functional of Rozanski & Woods: the rules for the allowed dependencies, and no unmapped code)." {
            include *
            autolayout
            properties {
                "rw.viewpoint" "functional"
            }
        }

        development = component frontend "Development" "The components of the container frontend (the viewpoint development of Rozanski & Woods: the rules for the layers, the cycles, the naming, and the annotations)." {
            include *
            autolayout
            properties {
                "rw.viewpoint" "development"
            }
        }

        information = component frontend "Information" "The components of the container frontend that own the data of the contract (the viewpoint information of Rozanski & Woods: the rule for the ownership of the data as a rule of dependency)." {
            include types
            include zod
            autolayout
            properties {
                "rw.viewpoint" "information"
            }
        }

        concurrency = dynamic system "Concurrency" "The containers of the system (the viewpoint concurrency of Rozanski & Woods, documentation only: the rules for the annotations)." {
            frontend -> backend
            autolayout
            properties {
                "rw.viewpoint" "concurrency"
            }
        }

        deployment = deployment system "The environment" "Deployment" "The deployment of the system (the viewpoint deployment of Rozanski & Woods, documentation only: the single deployment unit of the model)." {
            include *
            autolayout
            properties {
                "rw.viewpoint" "deployment"
            }
        }

        operational = container system "Operational" "The containers of the system (the viewpoint operational of Rozanski & Woods, documentation only)." {
            include *
            autolayout
            properties {
                "rw.viewpoint" "operational"
            }
        }
    }
}
