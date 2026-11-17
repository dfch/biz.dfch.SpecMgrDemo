---
classification: null
created: '2026-11-17T09:24:29.218+01:00'
id: 3ecb44fa-73d5-4985-9444-bfb444c321b3
status: draft
type: uc
updated: '2026-11-17T09:29:17.733+01:00'
version: 1.0.0
---

# Choose the Language

## Characteristic Information

### Goal in Context

User wants to read the page in English or in German.

### Scope

Frontend (the user interface of the SpecMgr Demo application, as a black box)

### Level

User Goal

### Preconditions

- User has a web browser and the address of the page.
- Frontend has a full catalog of text for English and for German.

### Success End Condition

- All text of the page is in the language that User selected.
- The button of the selected language shows that it is selected.
- The time of the check has the format of the selected language.

### Failed End Condition

- The page is in English, which is the language for each case that has no catalog.

### Primary Actor

User (a person with a web browser)

### Secondary Actors

- Browser (gives the list of the preferred languages of User)

### Trigger

User opens the page of the application.

### Frequency

At each time that a user opens the page. A user changes the language when the language that the page selected is not the language that the user wants.

### Priority

High

### Channels to Primary Actor

- Web browser (interactive, HTTP)

### Channels to Secondary Actors

- Browser: the list of the languages of the browser (the property `navigator.languages`)

## Main Success Scenario

1. Browser sends the list of the preferred languages to Frontend.
2. Frontend selects the first language of the list that has a catalog.
3. Frontend shows User the page with all text in the selected language and with the choice of the language.
    The button of the selected language shows that it is selected. The name on each button is in its own language: English and Deutsch. The attribute lang of the page and the title of the page have the selected language.
4. User selects the other language with its button.
5. Frontend shows User all text of the page in the other language.
    The text changes immediately. The browser does not get the page again and Frontend does not send a new request to Backend. The values that Backend gave stay the same. Only the text and the format of the time of the check change. The attribute lang of the page and the title of the page change too.
6. User reads the page in the other language.

## Extensions

### Extension 2a. The list has no language that has a catalog

1. Frontend selects English.
2. Continue to step 3.

### Extension 2b. The first language of the list has a region, for example de-CH

1. Frontend uses the first part of the language tag (de) and selects the catalog of this language.
2. Continue to step 3.

### Extension 5a. A section of the page shows an error

1. Frontend shows User the text for the error code in the other language.
    The trace identifier stays the same. Frontend does not send a new request to Backend.

## Sub-Variations

### Step 4: User can select

- The button English
- The button Deutsch

## Open Issues

- The page does not keep the choice of the language. If User opens the page again, Frontend selects the language again from the list of the browser.
- The project has no plan for a French catalog.

## Related Information

### Notes

- This use case is a part of UC "Open the Page". The language is for all sections of the page: the status, the notice and the error texts.
- REQ 52f9b02a-69e1-40db-af6e-ad3fb67987bc: The User Interface Is in English and in German
- REQ 848be85d-ba2c-44ec-b2d2-66fb0e6c84ef: The User Interface Shows an Error in the Language of the User

- VCR fc71e18f-8d48-44b5-baf7-5ec47941178e: Verification of the Use Case Choose the Language

### Assumptions

- The layout of the page works with the long German texts.
- The values from Backend (the address of the repository, the license, the version and the commit) do not change with the language.
