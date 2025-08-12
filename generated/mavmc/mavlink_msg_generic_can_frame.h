#pragma once
// MESSAGE GENERIC_CAN_FRAME PACKING

#define MAVLINK_MSG_ID_GENERIC_CAN_FRAME 200


typedef struct __mavlink_generic_can_frame_t {
 uint32_t timestamp; /*<  CAN frame timestamp*/
 uint16_t id; /*<  CAN frame ID*/
 uint8_t data[8]; /*<  CAN frame payload*/
} mavlink_generic_can_frame_t;

#define MAVLINK_MSG_ID_GENERIC_CAN_FRAME_LEN 14
#define MAVLINK_MSG_ID_GENERIC_CAN_FRAME_MIN_LEN 14
#define MAVLINK_MSG_ID_200_LEN 14
#define MAVLINK_MSG_ID_200_MIN_LEN 14

#define MAVLINK_MSG_ID_GENERIC_CAN_FRAME_CRC 26
#define MAVLINK_MSG_ID_200_CRC 26

#define MAVLINK_MSG_GENERIC_CAN_FRAME_FIELD_DATA_LEN 8

#if MAVLINK_COMMAND_24BIT
#define MAVLINK_MESSAGE_INFO_GENERIC_CAN_FRAME { \
    200, \
    "GENERIC_CAN_FRAME", \
    3, \
    {  { "timestamp", NULL, MAVLINK_TYPE_UINT32_T, 0, 0, offsetof(mavlink_generic_can_frame_t, timestamp) }, \
         { "id", NULL, MAVLINK_TYPE_UINT16_T, 0, 4, offsetof(mavlink_generic_can_frame_t, id) }, \
         { "data", NULL, MAVLINK_TYPE_UINT8_T, 8, 6, offsetof(mavlink_generic_can_frame_t, data) }, \
         } \
}
#else
#define MAVLINK_MESSAGE_INFO_GENERIC_CAN_FRAME { \
    "GENERIC_CAN_FRAME", \
    3, \
    {  { "timestamp", NULL, MAVLINK_TYPE_UINT32_T, 0, 0, offsetof(mavlink_generic_can_frame_t, timestamp) }, \
         { "id", NULL, MAVLINK_TYPE_UINT16_T, 0, 4, offsetof(mavlink_generic_can_frame_t, id) }, \
         { "data", NULL, MAVLINK_TYPE_UINT8_T, 8, 6, offsetof(mavlink_generic_can_frame_t, data) }, \
         } \
}
#endif

/**
 * @brief Pack a generic_can_frame message
 * @param system_id ID of this system
 * @param component_id ID of this component (e.g. 200 for IMU)
 * @param msg The MAVLink message to compress the data into
 *
 * @param timestamp  CAN frame timestamp
 * @param id  CAN frame ID
 * @param data  CAN frame payload
 * @return length of the message in bytes (excluding serial stream start sign)
 */
static inline uint16_t mavlink_msg_generic_can_frame_pack(uint8_t system_id, uint8_t component_id, mavlink_message_t* msg,
                               uint32_t timestamp, uint16_t id, const uint8_t *data)
{
#if MAVLINK_NEED_BYTE_SWAP || !MAVLINK_ALIGNED_FIELDS
    char buf[MAVLINK_MSG_ID_GENERIC_CAN_FRAME_LEN];
    _mav_put_uint32_t(buf, 0, timestamp);
    _mav_put_uint16_t(buf, 4, id);
    _mav_put_uint8_t_array(buf, 6, data, 8);
        memcpy(_MAV_PAYLOAD_NON_CONST(msg), buf, MAVLINK_MSG_ID_GENERIC_CAN_FRAME_LEN);
#else
    mavlink_generic_can_frame_t packet;
    packet.timestamp = timestamp;
    packet.id = id;
    mav_array_assign_uint8_t(packet.data, data, 8);
        memcpy(_MAV_PAYLOAD_NON_CONST(msg), &packet, MAVLINK_MSG_ID_GENERIC_CAN_FRAME_LEN);
#endif

    msg->msgid = MAVLINK_MSG_ID_GENERIC_CAN_FRAME;
    return mavlink_finalize_message(msg, system_id, component_id, MAVLINK_MSG_ID_GENERIC_CAN_FRAME_MIN_LEN, MAVLINK_MSG_ID_GENERIC_CAN_FRAME_LEN, MAVLINK_MSG_ID_GENERIC_CAN_FRAME_CRC);
}

/**
 * @brief Pack a generic_can_frame message
 * @param system_id ID of this system
 * @param component_id ID of this component (e.g. 200 for IMU)
 * @param status MAVLink status structure
 * @param msg The MAVLink message to compress the data into
 *
 * @param timestamp  CAN frame timestamp
 * @param id  CAN frame ID
 * @param data  CAN frame payload
 * @return length of the message in bytes (excluding serial stream start sign)
 */
static inline uint16_t mavlink_msg_generic_can_frame_pack_status(uint8_t system_id, uint8_t component_id, mavlink_status_t *_status, mavlink_message_t* msg,
                               uint32_t timestamp, uint16_t id, const uint8_t *data)
{
#if MAVLINK_NEED_BYTE_SWAP || !MAVLINK_ALIGNED_FIELDS
    char buf[MAVLINK_MSG_ID_GENERIC_CAN_FRAME_LEN];
    _mav_put_uint32_t(buf, 0, timestamp);
    _mav_put_uint16_t(buf, 4, id);
    _mav_put_uint8_t_array(buf, 6, data, 8);
        memcpy(_MAV_PAYLOAD_NON_CONST(msg), buf, MAVLINK_MSG_ID_GENERIC_CAN_FRAME_LEN);
#else
    mavlink_generic_can_frame_t packet;
    packet.timestamp = timestamp;
    packet.id = id;
    mav_array_memcpy(packet.data, data, sizeof(uint8_t)*8);
        memcpy(_MAV_PAYLOAD_NON_CONST(msg), &packet, MAVLINK_MSG_ID_GENERIC_CAN_FRAME_LEN);
#endif

    msg->msgid = MAVLINK_MSG_ID_GENERIC_CAN_FRAME;
#if MAVLINK_CRC_EXTRA
    return mavlink_finalize_message_buffer(msg, system_id, component_id, _status, MAVLINK_MSG_ID_GENERIC_CAN_FRAME_MIN_LEN, MAVLINK_MSG_ID_GENERIC_CAN_FRAME_LEN, MAVLINK_MSG_ID_GENERIC_CAN_FRAME_CRC);
#else
    return mavlink_finalize_message_buffer(msg, system_id, component_id, _status, MAVLINK_MSG_ID_GENERIC_CAN_FRAME_MIN_LEN, MAVLINK_MSG_ID_GENERIC_CAN_FRAME_LEN);
#endif
}

/**
 * @brief Pack a generic_can_frame message on a channel
 * @param system_id ID of this system
 * @param component_id ID of this component (e.g. 200 for IMU)
 * @param chan The MAVLink channel this message will be sent over
 * @param msg The MAVLink message to compress the data into
 * @param timestamp  CAN frame timestamp
 * @param id  CAN frame ID
 * @param data  CAN frame payload
 * @return length of the message in bytes (excluding serial stream start sign)
 */
static inline uint16_t mavlink_msg_generic_can_frame_pack_chan(uint8_t system_id, uint8_t component_id, uint8_t chan,
                               mavlink_message_t* msg,
                                   uint32_t timestamp,uint16_t id,const uint8_t *data)
{
#if MAVLINK_NEED_BYTE_SWAP || !MAVLINK_ALIGNED_FIELDS
    char buf[MAVLINK_MSG_ID_GENERIC_CAN_FRAME_LEN];
    _mav_put_uint32_t(buf, 0, timestamp);
    _mav_put_uint16_t(buf, 4, id);
    _mav_put_uint8_t_array(buf, 6, data, 8);
        memcpy(_MAV_PAYLOAD_NON_CONST(msg), buf, MAVLINK_MSG_ID_GENERIC_CAN_FRAME_LEN);
#else
    mavlink_generic_can_frame_t packet;
    packet.timestamp = timestamp;
    packet.id = id;
    mav_array_assign_uint8_t(packet.data, data, 8);
        memcpy(_MAV_PAYLOAD_NON_CONST(msg), &packet, MAVLINK_MSG_ID_GENERIC_CAN_FRAME_LEN);
#endif

    msg->msgid = MAVLINK_MSG_ID_GENERIC_CAN_FRAME;
    return mavlink_finalize_message_chan(msg, system_id, component_id, chan, MAVLINK_MSG_ID_GENERIC_CAN_FRAME_MIN_LEN, MAVLINK_MSG_ID_GENERIC_CAN_FRAME_LEN, MAVLINK_MSG_ID_GENERIC_CAN_FRAME_CRC);
}

/**
 * @brief Encode a generic_can_frame struct
 *
 * @param system_id ID of this system
 * @param component_id ID of this component (e.g. 200 for IMU)
 * @param msg The MAVLink message to compress the data into
 * @param generic_can_frame C-struct to read the message contents from
 */
static inline uint16_t mavlink_msg_generic_can_frame_encode(uint8_t system_id, uint8_t component_id, mavlink_message_t* msg, const mavlink_generic_can_frame_t* generic_can_frame)
{
    return mavlink_msg_generic_can_frame_pack(system_id, component_id, msg, generic_can_frame->timestamp, generic_can_frame->id, generic_can_frame->data);
}

/**
 * @brief Encode a generic_can_frame struct on a channel
 *
 * @param system_id ID of this system
 * @param component_id ID of this component (e.g. 200 for IMU)
 * @param chan The MAVLink channel this message will be sent over
 * @param msg The MAVLink message to compress the data into
 * @param generic_can_frame C-struct to read the message contents from
 */
static inline uint16_t mavlink_msg_generic_can_frame_encode_chan(uint8_t system_id, uint8_t component_id, uint8_t chan, mavlink_message_t* msg, const mavlink_generic_can_frame_t* generic_can_frame)
{
    return mavlink_msg_generic_can_frame_pack_chan(system_id, component_id, chan, msg, generic_can_frame->timestamp, generic_can_frame->id, generic_can_frame->data);
}

/**
 * @brief Encode a generic_can_frame struct with provided status structure
 *
 * @param system_id ID of this system
 * @param component_id ID of this component (e.g. 200 for IMU)
 * @param status MAVLink status structure
 * @param msg The MAVLink message to compress the data into
 * @param generic_can_frame C-struct to read the message contents from
 */
static inline uint16_t mavlink_msg_generic_can_frame_encode_status(uint8_t system_id, uint8_t component_id, mavlink_status_t* _status, mavlink_message_t* msg, const mavlink_generic_can_frame_t* generic_can_frame)
{
    return mavlink_msg_generic_can_frame_pack_status(system_id, component_id, _status, msg,  generic_can_frame->timestamp, generic_can_frame->id, generic_can_frame->data);
}

/**
 * @brief Send a generic_can_frame message
 * @param chan MAVLink channel to send the message
 *
 * @param timestamp  CAN frame timestamp
 * @param id  CAN frame ID
 * @param data  CAN frame payload
 */
#ifdef MAVLINK_USE_CONVENIENCE_FUNCTIONS

static inline void mavlink_msg_generic_can_frame_send(mavlink_channel_t chan, uint32_t timestamp, uint16_t id, const uint8_t *data)
{
#if MAVLINK_NEED_BYTE_SWAP || !MAVLINK_ALIGNED_FIELDS
    char buf[MAVLINK_MSG_ID_GENERIC_CAN_FRAME_LEN];
    _mav_put_uint32_t(buf, 0, timestamp);
    _mav_put_uint16_t(buf, 4, id);
    _mav_put_uint8_t_array(buf, 6, data, 8);
    _mav_finalize_message_chan_send(chan, MAVLINK_MSG_ID_GENERIC_CAN_FRAME, buf, MAVLINK_MSG_ID_GENERIC_CAN_FRAME_MIN_LEN, MAVLINK_MSG_ID_GENERIC_CAN_FRAME_LEN, MAVLINK_MSG_ID_GENERIC_CAN_FRAME_CRC);
#else
    mavlink_generic_can_frame_t packet;
    packet.timestamp = timestamp;
    packet.id = id;
    mav_array_assign_uint8_t(packet.data, data, 8);
    _mav_finalize_message_chan_send(chan, MAVLINK_MSG_ID_GENERIC_CAN_FRAME, (const char *)&packet, MAVLINK_MSG_ID_GENERIC_CAN_FRAME_MIN_LEN, MAVLINK_MSG_ID_GENERIC_CAN_FRAME_LEN, MAVLINK_MSG_ID_GENERIC_CAN_FRAME_CRC);
#endif
}

/**
 * @brief Send a generic_can_frame message
 * @param chan MAVLink channel to send the message
 * @param struct The MAVLink struct to serialize
 */
static inline void mavlink_msg_generic_can_frame_send_struct(mavlink_channel_t chan, const mavlink_generic_can_frame_t* generic_can_frame)
{
#if MAVLINK_NEED_BYTE_SWAP || !MAVLINK_ALIGNED_FIELDS
    mavlink_msg_generic_can_frame_send(chan, generic_can_frame->timestamp, generic_can_frame->id, generic_can_frame->data);
#else
    _mav_finalize_message_chan_send(chan, MAVLINK_MSG_ID_GENERIC_CAN_FRAME, (const char *)generic_can_frame, MAVLINK_MSG_ID_GENERIC_CAN_FRAME_MIN_LEN, MAVLINK_MSG_ID_GENERIC_CAN_FRAME_LEN, MAVLINK_MSG_ID_GENERIC_CAN_FRAME_CRC);
#endif
}

#if MAVLINK_MSG_ID_GENERIC_CAN_FRAME_LEN <= MAVLINK_MAX_PAYLOAD_LEN
/*
  This variant of _send() can be used to save stack space by reusing
  memory from the receive buffer.  The caller provides a
  mavlink_message_t which is the size of a full mavlink message. This
  is usually the receive buffer for the channel, and allows a reply to an
  incoming message with minimum stack space usage.
 */
static inline void mavlink_msg_generic_can_frame_send_buf(mavlink_message_t *msgbuf, mavlink_channel_t chan,  uint32_t timestamp, uint16_t id, const uint8_t *data)
{
#if MAVLINK_NEED_BYTE_SWAP || !MAVLINK_ALIGNED_FIELDS
    char *buf = (char *)msgbuf;
    _mav_put_uint32_t(buf, 0, timestamp);
    _mav_put_uint16_t(buf, 4, id);
    _mav_put_uint8_t_array(buf, 6, data, 8);
    _mav_finalize_message_chan_send(chan, MAVLINK_MSG_ID_GENERIC_CAN_FRAME, buf, MAVLINK_MSG_ID_GENERIC_CAN_FRAME_MIN_LEN, MAVLINK_MSG_ID_GENERIC_CAN_FRAME_LEN, MAVLINK_MSG_ID_GENERIC_CAN_FRAME_CRC);
#else
    mavlink_generic_can_frame_t *packet = (mavlink_generic_can_frame_t *)msgbuf;
    packet->timestamp = timestamp;
    packet->id = id;
    mav_array_assign_uint8_t(packet->data, data, 8);
    _mav_finalize_message_chan_send(chan, MAVLINK_MSG_ID_GENERIC_CAN_FRAME, (const char *)packet, MAVLINK_MSG_ID_GENERIC_CAN_FRAME_MIN_LEN, MAVLINK_MSG_ID_GENERIC_CAN_FRAME_LEN, MAVLINK_MSG_ID_GENERIC_CAN_FRAME_CRC);
#endif
}
#endif

#endif

// MESSAGE GENERIC_CAN_FRAME UNPACKING


/**
 * @brief Get field timestamp from generic_can_frame message
 *
 * @return  CAN frame timestamp
 */
static inline uint32_t mavlink_msg_generic_can_frame_get_timestamp(const mavlink_message_t* msg)
{
    return _MAV_RETURN_uint32_t(msg,  0);
}

/**
 * @brief Get field id from generic_can_frame message
 *
 * @return  CAN frame ID
 */
static inline uint16_t mavlink_msg_generic_can_frame_get_id(const mavlink_message_t* msg)
{
    return _MAV_RETURN_uint16_t(msg,  4);
}

/**
 * @brief Get field data from generic_can_frame message
 *
 * @return  CAN frame payload
 */
static inline uint16_t mavlink_msg_generic_can_frame_get_data(const mavlink_message_t* msg, uint8_t *data)
{
    return _MAV_RETURN_uint8_t_array(msg, data, 8,  6);
}

/**
 * @brief Decode a generic_can_frame message into a struct
 *
 * @param msg The message to decode
 * @param generic_can_frame C-struct to decode the message contents into
 */
static inline void mavlink_msg_generic_can_frame_decode(const mavlink_message_t* msg, mavlink_generic_can_frame_t* generic_can_frame)
{
#if MAVLINK_NEED_BYTE_SWAP || !MAVLINK_ALIGNED_FIELDS
    generic_can_frame->timestamp = mavlink_msg_generic_can_frame_get_timestamp(msg);
    generic_can_frame->id = mavlink_msg_generic_can_frame_get_id(msg);
    mavlink_msg_generic_can_frame_get_data(msg, generic_can_frame->data);
#else
        uint8_t len = msg->len < MAVLINK_MSG_ID_GENERIC_CAN_FRAME_LEN? msg->len : MAVLINK_MSG_ID_GENERIC_CAN_FRAME_LEN;
        memset(generic_can_frame, 0, MAVLINK_MSG_ID_GENERIC_CAN_FRAME_LEN);
    memcpy(generic_can_frame, _MAV_PAYLOAD(msg), len);
#endif
}
