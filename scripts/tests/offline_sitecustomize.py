"""Python socket guard for Hermes skills smoke child processes.

Scope: patches the stdlib ``socket`` module in the current interpreter only.
Native extensions, subprocesses without ``PYTHONPATH`` sitecustomize, or other
runtimes are outside this guard.
"""

from __future__ import annotations

import os
import socket

_DENY_LOG = os.environ.get("HERMES_SKILLS_SMOKE_DENY_LOG")
_LOOPBACK = {"127.0.0.1", "::1", "localhost"}
_ORIG_CONNECT = socket.socket.connect
_ORIG_CONNECT_EX = socket.socket.connect_ex
_ORIG_CREATE_CONNECTION = socket.create_connection
_ORIG_GETADDRINFO = socket.getaddrinfo
_ORIG_SENDTO = socket.socket.sendto
_ORIG_SENDMSG = getattr(socket.socket, "sendmsg", None)


class NetworkDenied(OSError):
    """Raised when skills smoke blocks an outbound network call."""


def _record(name: str) -> None:
    if not _DENY_LOG:
        return
    with open(_DENY_LOG, "a", encoding="utf-8") as handle:
        handle.write(f"{name}\n")


def _host_of(value: object) -> str:
    if isinstance(value, tuple) and value:
        return str(value[0]).lower().strip("[]")
    return str(value).lower().strip("[]")


def _is_loopback(value: object) -> bool:
    if value is None:
        return True
    return _host_of(value) in _LOOPBACK


def _deny(name: str):
    _record(name)
    raise NetworkDenied(f"network denied: {name}")


def _connect(self, address):
    if _is_loopback(address):
        return _ORIG_CONNECT(self, address)
    return _deny("connect")


def _connect_ex(self, address):
    if _is_loopback(address):
        return _ORIG_CONNECT_EX(self, address)
    return _deny("connect_ex")


def _create_connection(*args, **kwargs):
    address = args[0] if args else kwargs.get("address")
    if _is_loopback(address):
        return _ORIG_CREATE_CONNECTION(*args, **kwargs)
    return _deny("create_connection")


def _getaddrinfo(*args, **kwargs):
    host = args[0] if args else kwargs.get("host")
    if _is_loopback(host):
        return _ORIG_GETADDRINFO(*args, **kwargs)
    return _deny("getaddrinfo")


def _sendto(self, *args, **kwargs):
    address = args[1] if len(args) > 1 else kwargs.get("address")
    if _is_loopback(address):
        return _ORIG_SENDTO(self, *args, **kwargs)
    return _deny("sendto")


def _sendmsg(self, *args, **kwargs):
    address = args[3] if len(args) > 3 else kwargs.get("address")
    if _is_loopback(address):
        return _ORIG_SENDMSG(self, *args, **kwargs)
    return _deny("sendmsg")


def install() -> None:
    if getattr(socket.getaddrinfo, "_hermes_smoke_denied", False):
        os.environ["HERMES_SKILLS_SMOKE_NETGUARD"] = "1"
        return
    patched = (_connect, _connect_ex, _create_connection, _getaddrinfo, _sendto)
    for fn in patched:
        fn._hermes_smoke_denied = True
    socket.socket.connect = _connect
    socket.socket.connect_ex = _connect_ex
    socket.create_connection = _create_connection
    socket.getaddrinfo = _getaddrinfo
    socket.socket.sendto = _sendto
    if _ORIG_SENDMSG is not None:
        _sendmsg._hermes_smoke_denied = True
        socket.socket.sendmsg = _sendmsg
    os.environ["HERMES_SKILLS_SMOKE_NETGUARD"] = "1"


install()
