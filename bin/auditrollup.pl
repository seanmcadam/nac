#!/usr/bin/perl

use Data::Dumper;
use Carp;
use NAC::Audit;
use strict;

NAC::Audit::audit_daily_rollup();

