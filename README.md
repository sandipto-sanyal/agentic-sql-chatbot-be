# sample_flask_project
 This is a sample flask project
 
 # Setup
 Using any environment creation tool create a new environment. Below example shows how to do it from conda
 - ```conda create -n flask_env python=3.11.0```
 - ```conda activate flask_env```
 - ```pip install flask flask-cors```

 Open a command prompt in the project directory then run ```python app.py```.

 # Structure of project
 Since this project is created using Flask framework, it has to follow particular project structure for proper functioning.
 1. All .html files to be placed in ./templates
 1. All other static contents to be placed inside ./static. ./static may be optionally sub-divided into:
    1. ./static/css: To host custom CSS files
    1. ./static/js: To host custom js files
    1. ./static/fonts: To put custom fonts
    1. ./static/media: To put media contents like images, videos etc.

   
# Python Debugging Launch.json Configs
- https://code.visualstudio.com/docs/python/debugging#_set-configuration-options
