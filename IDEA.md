# Overview 

I need to demonstrate using Veeam Kasten to backup and restore a demo app running on ROKS (Redhat OpenShift at IBM Cloud). The demo app will be a vector db backed chat app all about animal facts. 

## Tech Stack
 - Python backend
 - Node/react frontend
 - VectorDB
 - RedHat OpenShift on Kubernetes (ROKS)
 - Local development via docker 
 - local tasks run via `mise` 

## Demo Flow
- Show Kasten overview and policy for demo app
- Show running app with basic animal facts
- Add new facts to DB
- Query new facts and query known missing facts (specific animal or species)
- Add incorrect fact to DB 
- Destroy/delete/kill vector DB
- Start restore in Kasten to just after incorrect fact was added
- show app running with incorrect info
- restore to before incorrect info was added
- added corrected info and show results 

## Instructions

1. Research vectorDBs well suited to run in containerized environments, pick the top 2 and list pros/cons of each in a RESEARCH.md file
2. Research python SDKs for interacting with suggested vector databases and append research to RESEARCH.md
3. As I want to use the IBM Carbon design system UI/UX style for the frontend of the app, create the required directory structure and html/css/js files needed to use the Carbon framework  
      - https://www.ibm.com/design/language/
      - https://carbondesignsystem.com/patterns/overview/ 	
4. Provide a public app API endpoint that shows the already known number of facts by animal. This way we have another visual representation of when the vector DB is removed and when we add new facts. 
