#!/bin/bash

echo "List of perl modules:"
echo "l" > /tmp/$$.commands
echo "q" >> /tmp/$$.commands
instmodsh < /tmp/$$.commands 
