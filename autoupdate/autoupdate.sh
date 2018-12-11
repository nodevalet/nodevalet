#!/bin/bash
# to be added to crontab to run updatebinaries and, if that fails, run updatefromsource

bash updatebinaries.sh || bash updatefromsource.sh
