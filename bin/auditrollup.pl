#!/usr/bin/perl

use FindBin;
use lib "$FindBin::Bin/../lib";
use Data::Dumper;
use Carp;
use NAC::Audit;
use strict;

NAC::Audit::audit_daily_rollup();

