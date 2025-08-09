# MAVLink - Mini Celka 

## Description
This is project that defines the minimal MAVLink 1.0 protocol for ```STM32 - PC(Matlab)``` communication


## Requirements
- Python 3.x
- Matlab2025a


### First ever launch of python enviroment:
1. Install appropriate version of Python, and navigate to the repo
2. Run the ```python -m venv venv```
3. Activate the enviroment ```source venv/Scripts/activate```
4. Installation of the packages ```pip install pymavlink```
5. When all packages are installed save requirements with ```pip freeze > requirements.txt```
6. To exit venv ```deactivate```

### Launching the enviroment after cloning or moving to a new machine:
1. Install appropriate version of Python, and navigate to the repo
2. Run the ```python -m venv venv```
3. Activate the enviroment ```source venv/Scripts/activate```
4. Install the packages ```pip install -r requirements.txt```
6. To exit venv ```deactivate```

### Generating 
1. Activate the enviroment ```source venv/Scripts/activate```
2. Run following command ```python venv/Scripts/mavgen.py --lang=C --wire-protocol=1.0 --output=generated mavmc.xml```
3. To exit venv ```deactivate```


## Useful resources:
- [SiK Radio Configuration](https://ardupilot.org/copter/docs/common-3dr-radio-advanced-configuration-and-technical-information.html?utm_source=chatgpt.com)
- [MAVLink Repository](https://github.com/mavlink/mavlink.git)
- []()
- []()
