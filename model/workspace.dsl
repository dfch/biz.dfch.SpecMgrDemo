workspace "SpecMgrDemo" "The architecture model of the project (DEC b6e8808f-86b4-41a4-92f2-33d38869beed and DEC e85e9685-0787-4dff-9ee5-9d46670e9ee4). The code must obey this model." {

    !impliedRelationships false

    model {
        system = softwareSystem "SpecMgrDemo" "The status API of the project: the backend (the Maven module) and the frontend (the pnpm module)." {
            perspectives {
                "Evolution" "The components of feat-9-walking-skeleton joined the model with the merge of that feature (feat-50-structurizr-model-rules, Phase 120, Task 120.110)." "Medium"
            }

            backend = container "backend" "The Maven module of the backend: the generated Spring server interfaces, the generated model classes and, since the walking skeleton (feat-9-walking-skeleton, Phase 200), the product code of the service." "Java 21 (Maven)" {
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
                        "specmgr-refs" "REQ 1ca335d7-969a-443e-9392-165fdeea99a0; REQ 271168a4-2a6f-40a1-b277-89711b18a087"
                    }
                }

                model = component "model" "The generated model classes (the top-level package biz.dfch.specmgrdemo.model)." "Java class" {
                    properties {
                        "code.language" "java"
                        "code.package" "biz.dfch.specmgrdemo.model"
                        "code.allowedExternal" "com.fasterxml.jackson.., org.springframework.., jakarta.validation.., jakarta.annotation"
                    }
                }

                app = component "app" "The product code of the service (the top-level package biz.dfch.specmgrdemo.app, feat-9-walking-skeleton, Phase 200): the main class, the controllers of the two operations, the check of the state, the error handling and the OpenTelemetry filter." "Java class" {
                    properties {
                        "code.language" "java"
                        "code.package" "biz.dfch.specmgrdemo.app"
                        "code.allowedExternal" "jakarta.servlet.., org.springframework.., io.opentelemetry.., org.slf4j"
                    }
                }

                api -> model "The interfaces of api reference the classes of model"
                app -> api "The controllers of app implement the generated interfaces of api"
                app -> model "The product code of app uses the classes of model (the state, the information and the problem of the operations)"
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
                        "code.allowedExternal" "vitest, fast-check, react, react-dom, react-i18next, @opentelemetry, node:http, node:net"
                    }
                }

                root = component "root" "The files that lie directly in frontend/src (the unit root: the entry point main.tsx of the walking skeleton and the example file mutation-example.ts)." "TypeScript" {
                    properties {
                        "code.language" "typescript"
                        "code.path" "src/mutation-example.ts, src/main.tsx"
                        "code.allowedExternal" "react, react-dom, react-i18next"
                    }
                }

                client = component "client" "The client of the API (the unit client, the folder frontend/src/client, feat-9-walking-skeleton, Phase 300): it calls GET /status and GET /info and validates the responses with the generated Zod schemas." "TypeScript" {
                    properties {
                        "code.language" "typescript"
                        "code.path" "src/client/**"
                        "code.allowedExternal" "zod"
                    }
                }

                i18n = component "i18n" "The i18n of the user interface (the unit i18n, the folder frontend/src/i18n, feat-9-walking-skeleton, Phase 300): i18next with the catalogs EN and DE." "TypeScript" {
                    properties {
                        "code.language" "typescript"
                        "code.path" "src/i18n/**"
                        "code.allowedExternal" "i18next, react-i18next"
                    }
                }

                telemetry = component "telemetry" "The OpenTelemetry of the browser (the unit telemetry, the folder frontend/src/telemetry, feat-9-walking-skeleton, Phase 300): the Web SDK and the exporter OTLP/HTTP." "TypeScript" {
                    properties {
                        "code.language" "typescript"
                        "code.path" "src/telemetry/**"
                        "code.allowedExternal" "@opentelemetry"
                    }
                }

                ui = component "ui" "The user interface (the unit ui, the folder frontend/src/ui, feat-9-walking-skeleton, Phase 300): the React components of the page of the status and of the notice of the license." "TypeScript" {
                    properties {
                        "code.language" "typescript"
                        "code.path" "src/ui/**"
                        "code.allowedExternal" "react, react-dom, react-i18next"
                    }
                }

                test -> zod "The tests import the generated Zod schemas"
                test -> root "The tests import the example file of frontend/src"
                test -> client "The tests import the client of the API"
                test -> i18n "The tests import the i18n"
                test -> telemetry "The tests import the telemetry"
                test -> ui "The tests import the user interface"
                test -> types "The tests import the generated types"
                root -> client "The entry point builds the client of the API"
                root -> i18n "The entry point builds the i18n"
                root -> telemetry "The entry point builds the telemetry"
                root -> ui "The entry point renders the user interface"
                client -> types "The client uses the generated types"
                client -> zod "The client validates the responses with the generated Zod schemas"
                ui -> client "The user interface uses the client of the API"
                ui -> i18n "The user interface uses the text of the i18n (the languages)"
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
            include client
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
