#!/usr/bin/env python3

import argparse
import logging
import sys
import traceback

from gerrit import Gerrit, Change, Expert


def dbg(msg):
    logging.debug(msg)


def err(msg):
    logging.error(msg)


def is_eligible_for_nothing(expert_, change_):
    dbg("Not Ready for anything")
    sys.exit(2)

def main(strategy_):
    parser = argparse.ArgumentParser(
        description="TF tool for pushing messages to Gerrit review")
    parser.add_argument("--debug", dest="debug", action="store_true")
    parser.add_argument("--gerrit", help="Gerrit URL", dest="gerrit", type=str)
    parser.add_argument("--review", help="Review ID", dest="review", type=str)
    parser.add_argument("--branch",
        help="Branch (optional, it is mundatory in case of cherry-picks)",
        dest="branch", type=str)
    parser.add_argument("--approvals",
        help="List of approvals to check. "
             "Format: <Name:Key[:Value>]>,<Name:Key>,...\n"
             "If Value is not provided then just checks if Key is present\n"
             "E.g. 'Verified:recommended:1,Code-Review:approved,Approved:approved'",
        dest="approvals", type=str,
        default='Verified:recommended:1,Code-Review:approved,Approved:approved')
    parser.add_argument("--user", help="Gerrit user", dest="user", type=str)
    parser.add_argument("--password", help="Gerrit API password",
        dest="password", type=str)
    args = parser.parse_args()

    log_level = logging.DEBUG if args.debug else logging.INFO
    logging.basicConfig(level=log_level)
    try:
        gerrit = Gerrit(args.gerrit, args.user, args.password)
        strategy_(Expert(gerrit), gerrit.get_current_change(args.review, args.branch))
    except Exception as e:
        print(traceback.format_exc())
        err("ERROR: failed to check approvals: %s" % e)
        sys.exit(1)


if __name__ == "__main__":
    main(is_eligible_for_nothing)
