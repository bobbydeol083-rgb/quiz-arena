'use strict';

const crypto = require('crypto');
const Room = require('../models/Room');
const Category = require('../models/Category');
const { errorBody, asyncHandler } = require('../utils/http');

const CODE_ALPHABET = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
const MAX_PLAYERS = 8;

async function generateUniqueCode() {
  for (let attempt = 0; attempt < 10; attempt++) {
    let code = '';
    for (let i = 0; i < 6; i++) {
      code += CODE_ALPHABET[crypto.randomInt(CODE_ALPHABET.length)];
    }
    if (!(await Room.findOne({ code }))) return code;
  }
  throw Object.assign(new Error('Could not generate a unique room code'), { status: 500, code: 'INTERNAL_ERROR' });
}

function serializeRoom(room) {
  return {
    id: String(room._id),
    code: room.code,
    mode: room.mode,
    status: room.status,
    category: room.category
      ? { id: String(room.category._id || room.category), name: room.category.name, icon: room.category.icon, color: room.category.color }
      : null,
    host: room.host
      ? { id: String(room.host._id || room.host), username: room.host.username, avatar: room.host.avatar }
      : null,
    players: (room.players || []).map((p) => ({
      id: String(p._id || p),
      username: p.username,
      avatar: p.avatar,
    })),
    questionCount: (room.questions || []).length,
    createdAt: room.createdAt,
  };
}

// POST /api/rooms { mode, category? }
const create = asyncHandler(async (req, res) => {
  const { mode = 'room', category } = req.body;

  let categoryDoc = null;
  if (category) {
    categoryDoc = await Category.findById(category);
    if (!categoryDoc) {
      return res.status(404).json(errorBody('CATEGORY_NOT_FOUND', 'Category not found'));
    }
  }

  const code = await generateUniqueCode();
  const room = await Room.create({
    code,
    host: req.userId,
    players: [req.userId],
    mode,
    category: categoryDoc ? categoryDoc._id : null,
    status: 'waiting',
  });

  res.status(201).json({ code, roomId: String(room._id) });
});

// GET /api/rooms/:code
const getByCode = asyncHandler(async (req, res) => {
  const code = String(req.params.code || '').toUpperCase();
  const room = await Room.findOne({ code })
    .populate('host', 'username avatar')
    .populate('players', 'username avatar')
    .populate('category', 'name icon color');
  if (!room) {
    return res.status(404).json(errorBody('ROOM_NOT_FOUND', 'Room not found'));
  }
  res.json({ room: serializeRoom(room) });
});

// POST /api/rooms/:code/join — REST join (realtime join lives on the socket)
const join = asyncHandler(async (req, res) => {
  const code = String(req.params.code || '').toUpperCase();
  const room = await Room.findOne({ code });
  if (!room) {
    return res.status(404).json(errorBody('ROOM_NOT_FOUND', 'Room not found'));
  }
  if (room.status !== 'waiting') {
    return res.status(409).json(errorBody('ROOM_CLOSED', 'Room is no longer accepting players'));
  }
  const already = room.players.some((p) => String(p) === req.userId);
  if (!already) {
    if (room.players.length >= MAX_PLAYERS) {
      return res.status(409).json(errorBody('ROOM_FULL', 'Room is full'));
    }
    room.players.push(req.userId);
    await room.save();
  }
  const populated = await Room.findById(room._id)
    .populate('host', 'username avatar')
    .populate('players', 'username avatar')
    .populate('category', 'name icon color');
  res.json({ room: serializeRoom(populated) });
});

module.exports = { create, getByCode, join, serializeRoom, MAX_PLAYERS };
