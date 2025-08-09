# MAVLink - Mini Celka 

## Description
This is project that defines the minimal MAVLink 1.0 protocol for ```STM32 - PC(Matlab)``` communication.

It includes the ```mavmc.xml``` file with frame definitions, that is the base for code generation with ```pymavlink```

IT also includes the ```radio_configuration_scripts``` that allows for AT commands configuration, here is original config that was on the radios:
```
ATI5
S0:FORMAT=26
S1:SERIAL_SPEED=115
S2:AIR_SPEED=128
S3:NETID=369
S4:TXPOWER=20
S5:ECC=0
S6:MAVLINK=1
S7:OPPRESEND=0
S8:MIN_FREQ=433050
S9:MAX_FREQ=434790
S10:NUM_CHANNELS=10
S11:DUTY_CYCLE=100
S12:LBT_RSSI=0
S13:MANCHESTER=0
S14:RTSCTS=0
S15:MAX_WINDOW=131
```
And here is my current config:
```
ATI5
S0:FORMAT=26
S1:SERIAL_SPEED=115
S2:AIR_SPEED=128
S3:NETID=369
S4:TXPOWER=2    
S5:ECC=0
S6:MAVLINK=1
S7:OPPRESEND=0
S8:MIN_FREQ=433050
S9:MAX_FREQ=434790
S10:NUM_CHANNELS=10
S11:DUTY_CYCLE=100
S12:LBT_RSSI=0
S13:MANCHESTER=0
S14:RTSCTS=0
S15:MAX_WINDOW=131
```


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
