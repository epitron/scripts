#!/usr/bin/env python
# -*- coding: utf-8 -*-

#license blarghs

"""This library provides useful quassel related tools

Documentation bogus here"""

import sqlite3
import time
import exceptions
import os
import re

class _conf:
    dbpath=("~/.config/quassel-irc.org/quassel-storage.sqlite", "~/.quassel/quassel-storage.sqlite")

"""
Buffer Types
0    InvalidBuffer = 0x00,
1    StatusBuffer = 0x01,
2    ChannelBuffer = 0x02,
4    QueryBuffer = 0x04,
8    GroupBuffer = 0x08

Message Types
1        Plain     = 0x0001,
2        Notice    = 0x0002,
4        Action    = 0x0004,
8        Nick      = 0x0008,
16        Mode      = 0x0010,
32        Join      = 0x0020,
64        Part      = 0x0040,
128        Quit      = 0x0080,
256        Kick      = 0x0100,
512        Kill      = 0x0200,
1024    Server    = 0x0400,
2048    Info      = 0x0800,
4096    Error     = 0x1000,
8192    DayChange = 0x2000

Message Flags (mostly internal, but may be useful)
0    None = 0x00,
1    Self = 0x01,
2    Highlight = 0x02,
4    Redirected = 0x04,
8    ServerMsg = 0x08,
128    Backlog = 0x80
"""
class QuasselError(exceptions.Exception):
    """base class for all quassel related exceptions"""
    pass

class NotFound(QuasselError):
    """Generic error when something was not found in a getter

    methods that throw this should be clear enough to guess the meaning"""
    pass

class Logformat:
    """Template class for log formatters, do not use directly
    
    row is a list with elements (type, flags, time, sender, message)
        type is message type, mostly for internal use
        flags is unneeded currently
        time is the time as unix timestamp
        sender is the sender as nick!ident@hostmask
        message is the message

    All output producing methods must return strings

    if you don't override methods, they will be forwarded to others()
    which can be used like an else-statement"""

    def __init__(self):
        """if overriding, always call parent unless you know what you're doing

        NOTE: Includes language specfic code for an english core"""
        #TODO: these strings are language specific for an english core
        self.topicchangere = re.compile('(\S+) has changed topic for (\S+) to: "(.*)"$')
        self.topicjoinre = re.compile('Topic for (\S+) is "(.*)"$')
        self.topicjoin2re = re.compile('Topic set by (\S+) on (\S+ \S+ \d+ \S+)')
    
    def format(self, row):
        """wrapper for the methods, most child classes should not touch this
        
        in most cases, you will call this method with a row to get a meaningful representation of that row"""
        if row[0] == 1:
            return self.message(row)
        elif row[0] == 2:
            return self.notice(row)
        elif row[0] == 4:
            return self.action(row)
        elif row[0] == 8:
            return self.nick(row)
        elif row[0] == 16:
            return self.mode(row)
        elif row[0] == 32:
            return self.join(row)
        elif row[0] == 64:
            return self.part(row)
        elif row[0] == 128:
            return self.quit(row)
        elif row[0] == 256:
            return self.kick(row)
        elif row[0] == 1024:
            return self._server(row)
        elif row[0] == 2048:
            return self.info(row)
        elif row[0] == 4096:
            return self.error(row)
        elif row[0] == 8192:
            return self.daychange(row)
        else:
            return self.others(row)

    def _server(self, row):
        match = self.topicchangere.search(row[4])
        if not match is None:
            (who, where, what) = match.groups()
            return self.topicchange(row[2], who, where, what)
        else:
            match = self.topicjoinre.search(row[4])
            if not match is None:
                (where, what) = match.groups()
                return self.topicjoin1(row[2], where, what)
            else:
                match = self.topicjoin2re.search(row[4])
                if not match is None:
                    (who, when) = match.groups()
                    return self.topicjoin2(row[2], who, when)
                else:
                    return self.server(row)
        
    def message(self, row):
        """defines format of regular messages"""
        return self.others(row)
    
    def notice(self, row):
        """defines format of notices"""
        return self.others(row)
    
    def action(self, row):
        """defines format of actions (/me)"""
        return self.others(row)
    
    def nick(self, row):
        """defines format of nickchanges"""
        return self.others(row)
    
    def mode(self, row):
        """defines format of modechanges"""
        return self.others(row)
    
    def join(self, row):
        """defines format of joins (including self)"""
        return self.others(row)
    
    def part(self, row):
        """defines format of parts (including self)"""
        return self.others(row)
    
    def quit(self, row):
        """defines format of quits (including self)"""
        return self.others(row)
    
    def kick(self, row):
        """defines format of kicks (including self)"""
        return self.others(row)
    
    def server(self, row):
        """defines format of server messages not including topic related messages"""
        return self.others(row)

    def topicchange(self, time, user, channel, topic):
        """defines format of generic topic changes"""
        return self.others(row)

    def topicjoin1(self, time, channel, topic):
        """defines format of channel join topic message, part one"""
        return self.others(row)

    def topicjoin2(self, time, user, logtime):
        """defines format of channel join topic message, part two"""
        return self.others(row)
    
    def info(self, row):
        """defines format of info lines"""
        return self.others(row)
    
    def error(self, row):
        """defines format of error lines"""
        return self.others(row)
    
    def daychange(self, row):
        """defines format of daychange message, mostly quassel specific"""
        return self.others(row)
    
    def others(self, row):
        """defines format of all types that you didn't override in your child, used to catch unhandled types"""
        return ""
    
class Logformat_mIRC (Logformat):
    def __init__(self, buffer):
        self.mynick = ""
        self.buffer = buffer
        Logformat.__init__(self)
        

    def _now(self, timestamp):
        return time.strftime("[%H:%M.%S]", time.localtime(timestamp))

    def _now2(self, timestamp):
        return time.strftime("%a %b %d %H:%M:%S %Y", time.localtime(timestamp))

    def message(self, row):
        sender = row[3].split("!")
        return "%s <%s> %s\n"%(self._now(row[2]), sender[0], row[4])
    
    def notice(self, row):
        sender = row[3].split("!")
        return "%s -%s- %s\n"%(self._now(row[2]), sender[0], row[4])
    
    def action(self, row):
        sender = row[3].split("!")
        return "%s * %s %s\n"%(self._now(row[2]), sender[0], row[4])
    
    def nick(self, row):
        if row[3] == row[4]:
            #own nick
            if self.mynick == "":
                #session start
                return "\nSession Start: %s\nSession Ident: %s\n"%(self._now2(row[2]), self.buffer)
            else:
                return "%s *** %s is now known as %s\n"%(self._now(row[2]), self.mynick, row[4])
            self.mynick = row[4]
        else:
            #Other people
            sender = row[3].split("!")
            return "%s *** %s is now known as %s\n"%(self._now(row[2]), sender[0], row[4])
                
    
    def mode(self, row):
        sender = row[3].split("!")
        return "%s *** %s sets mode: %s\n"%(self._now(row[2]), sender[0], " ".join(row[4].split(" ")[1:]))
    
    def join(self, row):
        sender = row[3].split("!")
        if self.mynick == "":
            #own nick
            self.mynick = sender[0]
            return "\nSession Start: %s\nSession Ident: %s\n"%(self._now2(row[2]), self.buffer)
        else:
            return "%s *** %s (%s) has joined %s\n"%(self._now(row[2]), sender[0], sender[1], row[4])
    
    def part(self, row):
        sender = row[3].split("!")
        if sender[0] == self.mynick:
            self.mynick = ""
            return "Session Close: %s\n"%self._now2(row[2])
        else:
            return "%s *** %s (%s) has left %s\n"%(self._now(row[2]), sender[0], sender[1], self.buffer)
    
    def quit(self, row):
        sender = row[3].split("!")
        if sender[0] == self.mynick:
            self.mynick = ""
            return "Session Close: %s\n"%self._now2(row[2])
        else:
            return "%s *** %s (%s) Quit (%s)\n"%(self._now(row[2]), sender[0], sender[1], row[4])
    
    def kick(self, row):
        sender = row[3].split("!")
        msg = row[4].split(" ")
        reason = " ".join(msg[1:])
        return "%s *** %s was kicked by %s (%s)\n"%(self._now(row[2]), msg[0], sender[0], reason)
    
    def server(self, row):
        return "%s *** %s\n"%(self._now(row[2]), row[4])

    def topicchange(self, time, user, channel, topic):
        return "%s *** %s changes topic to '%s'\n"%(self._now(time), user, topic)

    def topicjoin1(self, time, channel, topic):
        return "%s *** Topic is '%s\0'\n"%(self._now(time), topic)

    def topicjoin2(self, time, user, logtime):
        return "%s *** Set by %s on %s\n"%(self._now(time), user, logtime)

def mirc_color(num, num2=None):
    newnum = str(num).rjust(2, "0")
    if num2 is None:
        return "%c%s"%(3, newnum)
    else:
        new2 = str(num2).rjust(2, "0")
        return "%c%s.%s"%(3, newnum, new2)

class Logutil:
    _dbpath = None
    
    def __init__(self, dbpath=""):
        """returns a new Logutil instance.
        DB connection is shared between all logutils
        if dbpath is empty, try default paths (should work on most unixes)"""
        #if Logutil._con is None:
        if dbpath=="":
            self._open()
        else:
            if Logutil._dbpath is None:
                Logutil._dbpath = os.path.expanduser(dbpath)
            self.dbpath = os.path.expanduser(dbpath)
            #self.con = sqlite3.connect(os.path.expanduser(dbpath))
        #print (Logutil._dbpath)
        #print (self.dbpath)
    
    def _open(self):
        #TODO: POS Code, replace with something sane when sober
        #print ("open")
        for path in _conf.dbpath:
            if os.path.isfile(os.path.expanduser(path)):
                if Logutil._dbpath is None:
                    Logutil._dbpath = os.path.expanduser(path)
                self.dbpath = os.path.expanduser(path)
                
    
    def _time_to_unix(self, timestr):
        #Date
        year = 0
        month = 0
        day = 0
        hour = 0
        minute = 0
        second = 0
        match = re.compile("(\d{2,4})-(\d{2}).(\d{2})").search(timestr)
        if not match is None:
            (year, month, day) = match.groups()
        match = None
        match = re.compile("(\d{2}):(\d{2}):(\d{2})").search(timestr)
        if not match is None:
            (hour, minute, second) = match.groups()
        return time.mktime((int(year), int(month), int(day), int(hour), int(minute), int(second), -1, 0, -1))

    def cursor(self):
        """for thread safety, we need to do many connects for now"""
        con = sqlite3.connect(self.dbpath)
        return con.cursor()
    
    def get_users(self):
        query="""SELECT username FROM quasseluser"""
        cur = self.cursor()
        cur.execute(query)
        return [str(user[0]) for user in cur.fetchall()]

    def is_user(self, username):
        try:
            return username in self.get_users()
        except:
            return False
    
    def get_networks(self, username):
        query = """
        SELECT networkname
        FROM network
        JOIN quasseluser ON network.userid = quasseluser.userid
        WHERE username=?
        """
        cur = self.cursor()
        cur.execute(query, (username, ))
        return [str(network[0]) for network in cur.fetchall()]

    def is_network(self, username, network):
        try:
            return network in self.get_networks(username)
        except:
            return False
    
    def get_buffers(self, username, network):
        query = """
        SELECT buffername
        FROM buffer
        JOIN network ON buffer.networkid = network.networkid
        , quasseluser ON buffer.userid = quasseluser.userid
        WHERE username=?
        AND networkname=?
        """
        nwquery =  """
        SELECT networkname
        FROM network
        JOIN quasseluser ON network.userid = quasseluser.userid
        WHERE username=?
        """
        cur = self.cursor()
        if network is None:
            result = {}
            for nw in cur.execute(nwquery, (username, )):
                cur.execute(query, (username, nw[0]))
                result[str(nw[0])] = [str(buffer[0]) for buffer in cur.fetchall()]
        else:
            cur.execute(query, (username, network))
            result = [str(buf[0]) for buf in cur.fetchall()]
        return result
    
    def is_buffer(self, username, network, buffer):
        try:
            return buffer in self.get_buffers(username, network)
        except:
            return False
        
    def getlog(self, username, network, buffer, outstream, fmt=Logformat_mIRC(buffer), counter=None):
        """gets a logfile
        outstream must support .write() for strings
        fmt must be a Logformat child"""
        cur = self.cursor()
        query = """
        SELECT type, flags, time, sender, message
        FROM backlog
        JOIN sender ON backlog.senderid = sender.senderid
        , buffer ON backlog.bufferid = buffer.bufferid
        , network ON buffer.networkid = network.networkid
        , quasseluser ON buffer.userid = quasseluser.userid
        WHERE username=?
        AND networkname=?
        AND buffername=?
        """
        cur.execute(query, (username, network, buffer))
        all = cur.fetchall()
        if not counter is None:
            counter.set_max(len(all))
            counter.start()
        for row in all:
            if not counter is None:
                counter.next()
            outstream.write(fmt.format(row))
            #print fmt.format(row),
