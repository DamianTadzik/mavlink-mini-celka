#pragma once
// MESSAGE DEBUG_FRAME PACKING

#define MAVLINK_MSG_ID_DEBUG_FRAME 201


typedef struct __mavlink_debug_frame_t {
 uint8_t status; /*<  Status code*/
 char text[50]; /*<  Debug text (null-terminated if shorter)*/
} mavlink_debug_frame_t;

#define MAVLINK_MSG_ID_DEBUG_FRAME_LEN 51
#define MAVLINK_MSG_ID_DEBUG_FRAME_MIN_LEN 51
#define MAVLINK_MSG_ID_201_LEN 51
#define MAVLINK_MSG_ID_201_MIN_LEN 51

#define MAVLINK_MSG_ID_DEBUG_FRAME_CRC 44
#define MAVLINK_MSG_ID_201_CRC 44

#define MAVLINK_MSG_DEBUG_FRAME_FIELD_TEXT_LEN 50

#if MAVLINK_COMMAND_24BIT
#define MAVLINK_MESSAGE_INFO_DEBUG_FRAME { \
    201, \
    "DEBUG_FRAME", \
    2, \
    {  { "status", NULL, MAVLINK_TYPE_UINT8_T, 0, 0, offsetof(mavlink_debug_frame_t, status) }, \
         { "text", NULL, MAVLINK_TYPE_CHAR, 50, 1, offsetof(mavlink_debug_frame_t, text) }, \
         } \
}
#else
#define MAVLINK_MESSAGE_INFO_DEBUG_FRAME { \
    "DEBUG_FRAME", \
    2, \
    {  { "status", NULL, MAVLINK_TYPE_UINT8_T, 0, 0, offsetof(mavlink_debug_frame_t, status) }, \
         { "text", NULL, MAVLINK_TYPE_CHAR, 50, 1, offsetof(mavlink_debug_frame_t, text) }, \
         } \
}
#endif

/**
 * @brief Pack a debug_frame message
 * @param system_id ID of this system
 * @param component_id ID of this component (e.g. 200 for IMU)
 * @param msg The MAVLink message to compress the data into
 *
 * @param status  Status code
 * @param text  Debug text (null-terminated if shorter)
 * @return length of the message in bytes (excluding serial stream start sign)
 */
static inline uint16_t mavlink_msg_debug_frame_pack(uint8_t system_id, uint8_t component_id, mavlink_message_t* msg,
                               uint8_t status, const char *text)
{
#if MAVLINK_NEED_BYTE_SWAP || !MAVLINK_ALIGNED_FIELDS
    char buf[MAVLINK_MSG_ID_DEBUG_FRAME_LEN];
    _mav_put_uint8_t(buf, 0, status);
    _mav_put_char_array(buf, 1, text, 50);
        memcpy(_MAV_PAYLOAD_NON_CONST(msg), buf, MAVLINK_MSG_ID_DEBUG_FRAME_LEN);
#else
    mavlink_debug_frame_t packet;
    packet.status = status;
    mav_array_assign_char(packet.text, text, 50);
        memcpy(_MAV_PAYLOAD_NON_CONST(msg), &packet, MAVLINK_MSG_ID_DEBUG_FRAME_LEN);
#endif

    msg->msgid = MAVLINK_MSG_ID_DEBUG_FRAME;
    return mavlink_finalize_message(msg, system_id, component_id, MAVLINK_MSG_ID_DEBUG_FRAME_MIN_LEN, MAVLINK_MSG_ID_DEBUG_FRAME_LEN, MAVLINK_MSG_ID_DEBUG_FRAME_CRC);
}

/**
 * @brief Pack a debug_frame message
 * @param system_id ID of this system
 * @param component_id ID of this component (e.g. 200 for IMU)
 * @param status MAVLink status structure
 * @param msg The MAVLink message to compress the data into
 *
 * @param status  Status code
 * @param text  Debug text (null-terminated if shorter)
 * @return length of the message in bytes (excluding serial stream start sign)
 */
static inline uint16_t mavlink_msg_debug_frame_pack_status(uint8_t system_id, uint8_t component_id, mavlink_status_t *_status, mavlink_message_t* msg,
                               uint8_t status, const char *text)
{
#if MAVLINK_NEED_BYTE_SWAP || !MAVLINK_ALIGNED_FIELDS
    char buf[MAVLINK_MSG_ID_DEBUG_FRAME_LEN];
    _mav_put_uint8_t(buf, 0, status);
    _mav_put_char_array(buf, 1, text, 50);
        memcpy(_MAV_PAYLOAD_NON_CONST(msg), buf, MAVLINK_MSG_ID_DEBUG_FRAME_LEN);
#else
    mavlink_debug_frame_t packet;
    packet.status = status;
    mav_array_memcpy(packet.text, text, sizeof(char)*50);
        memcpy(_MAV_PAYLOAD_NON_CONST(msg), &packet, MAVLINK_MSG_ID_DEBUG_FRAME_LEN);
#endif

    msg->msgid = MAVLINK_MSG_ID_DEBUG_FRAME;
#if MAVLINK_CRC_EXTRA
    return mavlink_finalize_message_buffer(msg, system_id, component_id, _status, MAVLINK_MSG_ID_DEBUG_FRAME_MIN_LEN, MAVLINK_MSG_ID_DEBUG_FRAME_LEN, MAVLINK_MSG_ID_DEBUG_FRAME_CRC);
#else
    return mavlink_finalize_message_buffer(msg, system_id, component_id, _status, MAVLINK_MSG_ID_DEBUG_FRAME_MIN_LEN, MAVLINK_MSG_ID_DEBUG_FRAME_LEN);
#endif
}

/**
 * @brief Pack a debug_frame message on a channel
 * @param system_id ID of this system
 * @param component_id ID of this component (e.g. 200 for IMU)
 * @param chan The MAVLink channel this message will be sent over
 * @param msg The MAVLink message to compress the data into
 * @param status  Status code
 * @param text  Debug text (null-terminated if shorter)
 * @return length of the message in bytes (excluding serial stream start sign)
 */
static inline uint16_t mavlink_msg_debug_frame_pack_chan(uint8_t system_id, uint8_t component_id, uint8_t chan,
                               mavlink_message_t* msg,
                                   uint8_t status,const char *text)
{
#if MAVLINK_NEED_BYTE_SWAP || !MAVLINK_ALIGNED_FIELDS
    char buf[MAVLINK_MSG_ID_DEBUG_FRAME_LEN];
    _mav_put_uint8_t(buf, 0, status);
    _mav_put_char_array(buf, 1, text, 50);
        memcpy(_MAV_PAYLOAD_NON_CONST(msg), buf, MAVLINK_MSG_ID_DEBUG_FRAME_LEN);
#else
    mavlink_debug_frame_t packet;
    packet.status = status;
    mav_array_assign_char(packet.text, text, 50);
        memcpy(_MAV_PAYLOAD_NON_CONST(msg), &packet, MAVLINK_MSG_ID_DEBUG_FRAME_LEN);
#endif

    msg->msgid = MAVLINK_MSG_ID_DEBUG_FRAME;
    return mavlink_finalize_message_chan(msg, system_id, component_id, chan, MAVLINK_MSG_ID_DEBUG_FRAME_MIN_LEN, MAVLINK_MSG_ID_DEBUG_FRAME_LEN, MAVLINK_MSG_ID_DEBUG_FRAME_CRC);
}

/**
 * @brief Encode a debug_frame struct
 *
 * @param system_id ID of this system
 * @param component_id ID of this component (e.g. 200 for IMU)
 * @param msg The MAVLink message to compress the data into
 * @param debug_frame C-struct to read the message contents from
 */
static inline uint16_t mavlink_msg_debug_frame_encode(uint8_t system_id, uint8_t component_id, mavlink_message_t* msg, const mavlink_debug_frame_t* debug_frame)
{
    return mavlink_msg_debug_frame_pack(system_id, component_id, msg, debug_frame->status, debug_frame->text);
}

/**
 * @brief Encode a debug_frame struct on a channel
 *
 * @param system_id ID of this system
 * @param component_id ID of this component (e.g. 200 for IMU)
 * @param chan The MAVLink channel this message will be sent over
 * @param msg The MAVLink message to compress the data into
 * @param debug_frame C-struct to read the message contents from
 */
static inline uint16_t mavlink_msg_debug_frame_encode_chan(uint8_t system_id, uint8_t component_id, uint8_t chan, mavlink_message_t* msg, const mavlink_debug_frame_t* debug_frame)
{
    return mavlink_msg_debug_frame_pack_chan(system_id, component_id, chan, msg, debug_frame->status, debug_frame->text);
}

/**
 * @brief Encode a debug_frame struct with provided status structure
 *
 * @param system_id ID of this system
 * @param component_id ID of this component (e.g. 200 for IMU)
 * @param status MAVLink status structure
 * @param msg The MAVLink message to compress the data into
 * @param debug_frame C-struct to read the message contents from
 */
static inline uint16_t mavlink_msg_debug_frame_encode_status(uint8_t system_id, uint8_t component_id, mavlink_status_t* _status, mavlink_message_t* msg, const mavlink_debug_frame_t* debug_frame)
{
    return mavlink_msg_debug_frame_pack_status(system_id, component_id, _status, msg,  debug_frame->status, debug_frame->text);
}

/**
 * @brief Send a debug_frame message
 * @param chan MAVLink channel to send the message
 *
 * @param status  Status code
 * @param text  Debug text (null-terminated if shorter)
 */
#ifdef MAVLINK_USE_CONVENIENCE_FUNCTIONS

static inline void mavlink_msg_debug_frame_send(mavlink_channel_t chan, uint8_t status, const char *text)
{
#if MAVLINK_NEED_BYTE_SWAP || !MAVLINK_ALIGNED_FIELDS
    char buf[MAVLINK_MSG_ID_DEBUG_FRAME_LEN];
    _mav_put_uint8_t(buf, 0, status);
    _mav_put_char_array(buf, 1, text, 50);
    _mav_finalize_message_chan_send(chan, MAVLINK_MSG_ID_DEBUG_FRAME, buf, MAVLINK_MSG_ID_DEBUG_FRAME_MIN_LEN, MAVLINK_MSG_ID_DEBUG_FRAME_LEN, MAVLINK_MSG_ID_DEBUG_FRAME_CRC);
#else
    mavlink_debug_frame_t packet;
    packet.status = status;
    mav_array_assign_char(packet.text, text, 50);
    _mav_finalize_message_chan_send(chan, MAVLINK_MSG_ID_DEBUG_FRAME, (const char *)&packet, MAVLINK_MSG_ID_DEBUG_FRAME_MIN_LEN, MAVLINK_MSG_ID_DEBUG_FRAME_LEN, MAVLINK_MSG_ID_DEBUG_FRAME_CRC);
#endif
}

/**
 * @brief Send a debug_frame message
 * @param chan MAVLink channel to send the message
 * @param struct The MAVLink struct to serialize
 */
static inline void mavlink_msg_debug_frame_send_struct(mavlink_channel_t chan, const mavlink_debug_frame_t* debug_frame)
{
#if MAVLINK_NEED_BYTE_SWAP || !MAVLINK_ALIGNED_FIELDS
    mavlink_msg_debug_frame_send(chan, debug_frame->status, debug_frame->text);
#else
    _mav_finalize_message_chan_send(chan, MAVLINK_MSG_ID_DEBUG_FRAME, (const char *)debug_frame, MAVLINK_MSG_ID_DEBUG_FRAME_MIN_LEN, MAVLINK_MSG_ID_DEBUG_FRAME_LEN, MAVLINK_MSG_ID_DEBUG_FRAME_CRC);
#endif
}

#if MAVLINK_MSG_ID_DEBUG_FRAME_LEN <= MAVLINK_MAX_PAYLOAD_LEN
/*
  This variant of _send() can be used to save stack space by reusing
  memory from the receive buffer.  The caller provides a
  mavlink_message_t which is the size of a full mavlink message. This
  is usually the receive buffer for the channel, and allows a reply to an
  incoming message with minimum stack space usage.
 */
static inline void mavlink_msg_debug_frame_send_buf(mavlink_message_t *msgbuf, mavlink_channel_t chan,  uint8_t status, const char *text)
{
#if MAVLINK_NEED_BYTE_SWAP || !MAVLINK_ALIGNED_FIELDS
    char *buf = (char *)msgbuf;
    _mav_put_uint8_t(buf, 0, status);
    _mav_put_char_array(buf, 1, text, 50);
    _mav_finalize_message_chan_send(chan, MAVLINK_MSG_ID_DEBUG_FRAME, buf, MAVLINK_MSG_ID_DEBUG_FRAME_MIN_LEN, MAVLINK_MSG_ID_DEBUG_FRAME_LEN, MAVLINK_MSG_ID_DEBUG_FRAME_CRC);
#else
    mavlink_debug_frame_t *packet = (mavlink_debug_frame_t *)msgbuf;
    packet->status = status;
    mav_array_assign_char(packet->text, text, 50);
    _mav_finalize_message_chan_send(chan, MAVLINK_MSG_ID_DEBUG_FRAME, (const char *)packet, MAVLINK_MSG_ID_DEBUG_FRAME_MIN_LEN, MAVLINK_MSG_ID_DEBUG_FRAME_LEN, MAVLINK_MSG_ID_DEBUG_FRAME_CRC);
#endif
}
#endif

#endif

// MESSAGE DEBUG_FRAME UNPACKING


/**
 * @brief Get field status from debug_frame message
 *
 * @return  Status code
 */
static inline uint8_t mavlink_msg_debug_frame_get_status(const mavlink_message_t* msg)
{
    return _MAV_RETURN_uint8_t(msg,  0);
}

/**
 * @brief Get field text from debug_frame message
 *
 * @return  Debug text (null-terminated if shorter)
 */
static inline uint16_t mavlink_msg_debug_frame_get_text(const mavlink_message_t* msg, char *text)
{
    return _MAV_RETURN_char_array(msg, text, 50,  1);
}

/**
 * @brief Decode a debug_frame message into a struct
 *
 * @param msg The message to decode
 * @param debug_frame C-struct to decode the message contents into
 */
static inline void mavlink_msg_debug_frame_decode(const mavlink_message_t* msg, mavlink_debug_frame_t* debug_frame)
{
#if MAVLINK_NEED_BYTE_SWAP || !MAVLINK_ALIGNED_FIELDS
    debug_frame->status = mavlink_msg_debug_frame_get_status(msg);
    mavlink_msg_debug_frame_get_text(msg, debug_frame->text);
#else
        uint8_t len = msg->len < MAVLINK_MSG_ID_DEBUG_FRAME_LEN? msg->len : MAVLINK_MSG_ID_DEBUG_FRAME_LEN;
        memset(debug_frame, 0, MAVLINK_MSG_ID_DEBUG_FRAME_LEN);
    memcpy(debug_frame, _MAV_PAYLOAD(msg), len);
#endif
}
