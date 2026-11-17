workspace "SpecMgrDemo" "The architecture model of the demo (feat-0-demoprep). Hand conversion of model/workspace.json with views. A precursor of feat-50." {

    !identifiers hierarchical

    model {
        visitor = person "Visitor" "A person that opens the user interface in a browser."

        s = softwareSystem "SpecMgrDemo" "The walking skeleton: GET /status and GET /info, with a user interface." {
            properties {
                "specmgr-req" "1ca335d7-969a-443e-9392-165fdeea99a0, 271168a4-2a6f-40a1-b277-89711b18a087"
            }

            backend = container "backend" "The Maven module of the backend: the generated Spring server interfaces, the generated model classes and the product code." "Java 21 (Maven)" {
                properties {
                    "code.language" "java"
                    "code.root" "backend/src"
                }

                api = component "api" "The generated Spring server interfaces (the top-level package biz.dfch.specmgrdemo.api)." "Java interface" {
                    properties {
                        "specmgr-req" "1ca335d7-969a-443e-9392-165fdeea99a0, 271168a4-2a6f-40a1-b277-89711b18a087"
                        "code.language" "java"
                        "code.package" "biz.dfch.specmgrdemo.api"
                    }
                }
                model = component "model" "The generated model classes (the top-level package biz.dfch.specmgrdemo.model)." "Java class" {
                    properties {
                        "code.language" "java"
                        "code.package" "biz.dfch.specmgrdemo.model"
                    }
                }
                app = component "app" "The product code: the controllers, the problem advice, the trace filter and the OpenTelemetry configuration." "Java class" {
                    properties {
                        "code.language" "java"
                        "code.package" "biz.dfch.specmgrdemo.app"
                    }
                }
            }

            frontend = container "frontend" "The pnpm module of the frontend: the user interface (React), the client of the API, i18n, telemetry and the generated code." "TypeScript (pnpm)" {
                properties {
                    "code.language" "typescript"
                    "code.root" "frontend/src"
                }

                types = component "types" "The generated TypeScript types (the unit types, the folder frontend/src/generated/types)." "TypeScript" {
                    properties {
                        "code.language" "typescript"
                        "code.path" "frontend/src/generated/types"
                    }
                }
                zod = component "zod" "The generated Zod schemas (the unit zod, the folder frontend/src/generated/zod)." "TypeScript" {
                    properties {
                        "code.language" "typescript"
                        "code.path" "frontend/src/generated/zod"
                    }
                }
                client = component "client" "The client of the API: GET /status and GET /info. It validates each response with the Zod schemas." "TypeScript" {
                    properties {
                        "code.language" "typescript"
                        "code.path" "frontend/src/client"
                    }
                }
                i18n = component "i18n" "The text of the user interface in English and German." "TypeScript" {
                    properties {
                        "code.language" "typescript"
                        "code.path" "frontend/src/i18n"
                    }
                }
                telemetry = component "telemetry" "The OpenTelemetry of the browser." "TypeScript" {
                    properties {
                        "code.language" "typescript"
                        "code.path" "frontend/src/telemetry"
                    }
                }
                ui = component "ui" "The React components: the state of GET /status and the notice of the license of GET /info." "TypeScript" {
                    properties {
                        "specmgr-req" "271168a4-2a6f-40a1-b277-89711b18a087"
                        "code.language" "typescript"
                        "code.path" "frontend/src/ui"
                    }
                }
                root = component "root" "The entry point (the files that lie directly in frontend/src)." "TypeScript" {
                    properties {
                        "code.language" "typescript"
                        "code.path" "frontend/src/*.ts*"
                    }
                }
                test = component "test" "The tests of the module (the unit test, the folder frontend/src/test)." "TypeScript" {
                    tags "Test"
                    properties {
                        "code.language" "typescript"
                        "code.path" "frontend/src/test"
                    }
                }
            }
        }

        visitor -> s.frontend "Opens the page in a browser"
        s.frontend -> s.backend "The frontend consumes the API of the backend"

        s.backend.api -> s.backend.model "references"
        s.backend.app -> s.backend.api "implements"
        s.backend.app -> s.backend.model "uses"

        s.frontend.client -> s.frontend.types "uses"
        s.frontend.client -> s.frontend.zod "validates with"
        s.frontend.ui -> s.frontend.client "uses"
        s.frontend.ui -> s.frontend.i18n "uses the text of"
        s.frontend.root -> s.frontend.client "builds"
        s.frontend.root -> s.frontend.i18n "builds"
        s.frontend.root -> s.frontend.telemetry "builds"
        s.frontend.root -> s.frontend.ui "renders"
        s.frontend.test -> s.frontend.zod "imports"
        s.frontend.test -> s.frontend.types "imports"
        s.frontend.test -> s.frontend.root "imports"
        s.frontend.test -> s.frontend.client "imports"
        s.frontend.test -> s.frontend.i18n "imports"
        s.frontend.test -> s.frontend.telemetry "imports"
        s.frontend.test -> s.frontend.ui "imports"
    }

    views {
        systemContext s "Context" "Level 1: the system and its user." {
            include *
            autoLayout lr
            properties {
                "rw.viewpoint" "context"
            }
        }

        container s "Containers" "Level 2: the backend and the frontend." {
            include *
            autoLayout lr
            properties {
                "rw.viewpoint" "functional"
            }
        }

        component s.backend "Backend" "Level 3: the packages of the backend. The code must obey the arrows." {
            include *
            autoLayout lr 150 100
            properties {
                "rw.viewpoint" "development"
            }
        }

        component s.frontend "Frontend" "Level 3: the units of the frontend. The code must obey the arrows." {
            include *
            exclude s.frontend.test
            autoLayout tb
            properties {
                "rw.viewpoint" "development"
            }
        }

        styles {
            element "Element" {
                color #ffffff
            }
            element "Person" {
                shape person
                background #08427b
            }
            element "Software System" {
                background #1168bd
            }
            element "Container" {
                background #438dd5
            }
            element "Component" {
                background #85bb65
                color #000000
            }
            element "Test" {
                background #bbbbbb
            }
        }
    }

    configuration {
        scope softwaresystem
    }

}
