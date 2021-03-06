/*
	CDThreeButtonControl.m
	cocoaDialog
	Copyright (C) 2004-2006 Mark A. Stratman <mark@sporkstorms.org>
 
	This program is free software; you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation; either version 2 of the License, or
	(at your option) any later version.
 
	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.
 
	You should have received a copy of the GNU General Public License
	along with this program; if not, write to the Free Software
	Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
*/

#import "CDThreeButtonControl.h"

@implementation CDThreeButtonControl

- (NSString *) controlNib {
    return  @"tbc";
}

- (NSDictionary *) globalAvailableKeys
{
	NSNumber *vOne = [NSNumber numberWithInt:CDOptionsOneValue];
	NSNumber *vNone = [NSNumber numberWithInt:CDOptionsNoValues];
	return [NSDictionary dictionaryWithObjectsAndKeys:
            // General
            vNone, @"help",
            vNone, @"debug",
            vNone, @"quiet",
            vOne,  @"timeout",
            vOne,  @"timeout-format",
            vNone, @"string-output",
            vNone, @"no-newline",
            // Panel
            vNone, @"close",
            vOne,  @"height",
            vOne,  @"max-height",
            vOne,  @"max-width",
            vOne,  @"min-height",
            vOne,  @"min-width",
            vNone, @"minimize",
            vNone, @"no-float",
            vOne,  @"posX",
            vOne,  @"posY",
            vNone, @"resize",
            vOne,  @"screen",
            vOne,  @"title",
            vOne,  @"width",
            // Icon
            vOne,  @"icon",
            vOne,  @"icon-bundle",
            vOne,  @"icon-type",
            vOne,  @"icon-file",
            vOne,  @"icon-size",
            vOne,  @"icon-width",
            vOne,  @"icon-height",
            // CDThreeButtonControl
            vOne,  @"label",
            vOne,  @"button1",
            vOne,  @"button2",
            vOne,  @"button3",
            vOne,  @"cancel",
            vNone, @"value-required",
            vOne,  @"empty-text",
            nil];
}


// Needs to be overriden in control
- (void) setControl:(id)sender { }

- (void) setControl: (id)sender matrixRows:(NSInteger)rows matrixColumns:(NSInteger)columns items:(NSArray *)items precedence:(int)precedence
{
    if (controlMatrix != nil) {
        // Default exact columns/rows
        unsigned long exactColumns = [items count] / rows;
        float exactColumnsFloat = (float) [items count] / (float)rows;
        
        unsigned long exactRows = [items count] / columns;
        float exactRowsFloat = (float)[items count] / (float)columns;
        
        switch (precedence) {
                // Rows have precedence over columns, if items extend past number of rows
                // columns will be increased to account for the additional items.
            case 1:
                // Items do not fill rows, reduce the rows to fit
                if (exactRowsFloat < (float)rows) {
                    rows = exactRows;
                }
                // Items exceed rows, expand columns
                else if (exactRowsFloat > (float)rows) {
                    columns = [items count] / rows;
                    exactColumnsFloat = (float)[items count] / (float)rows;
                    if (exactColumnsFloat > (float) columns) {
                        columns++;
                    }
                }
                // Extend rows once more if the division is greater than a whole number
                if (exactColumnsFloat > (float) columns) {
                    columns++;
                }
                break;
                
                // Columns have precedence over rows, if items extend past number of columns
                // rows will be increased to account for the additional items.
            default:
                // Items do not fill columns, reduce the columns to fit
                if (exactColumnsFloat < (float)columns) {
                    columns = (int) exactColumns;
                }
                // Items exceed columns, expand rows
                else if (exactColumnsFloat > (float)columns) {
                    rows = [items count] / columns;
                    exactRowsFloat = (float)[items count] / (float)columns;
                    if (exactRowsFloat > (float) rows) {
                        rows++;
                    }
                    exactColumnsFloat = (float) [items count] / (float)rows;
                    if (exactColumnsFloat <= (float)columns) {
                        columns = (int) exactColumnsFloat;
                    }
                }
                // Extend rows once more if the division is greater than a whole number
                if (exactRowsFloat > (float) rows) {
                    rows++;
                }
                break;
        }
        // Tell the matrix how many rows and columns it has
        [controlMatrix renewRows:rows columns:columns];
    }
}

- (void) setTitle:(NSString*)aTitle forButton:(NSButton*)aButton
{
	if (aTitle && ![aTitle isEqualToString:@""]) {
		[aButton setTitle:aTitle];
		float maxX = NSMaxX([aButton frame]);
		[aButton sizeToFit];
		NSRect r = [aButton frame];
		r.size.width += 12.0f;
		if (maxX > 100.0f) { // button is in the right side
			r.origin.x = maxX - NSWidth(r);
		}
		[aButton setFrame:r];
		[aButton setEnabled:YES];
		[aButton setHidden:NO];
	} else {
		[aButton setEnabled:NO];
		[aButton setHidden:YES];
	}
}

// This resizes
- (void) setTitleButtonsLabel:(NSString *)labelText {
    [panel setMaxHeight:0];
    [panel setMaxWidth:[self screen].size.width / 2];
    [panel resize];

	[self setButtons];
    [self setLabel:labelText];
    if (expandingLabel != nil && ![[icon controls] containsObject:expandingLabel]) {
        [icon addControl:expandingLabel];
    }
        
    if (controlMatrix != nil) {
        // Remember old controlMatrix size
        NSRect m = [controlMatrix frame];
        float oldHeight = m.size.height;
        float oldWidth = m.size.width;
        // Call the control
        [self setControl:self];
        // Resize
        [controlMatrix sizeToCells];
        [[controlMatrix superview] setNeedsDisplay:YES];
        // Position
        m = [controlMatrix frame];
        m.origin.y -= m.size.height - oldHeight;
        [controlMatrix setFrameOrigin:m.origin];
        // Position Timeout Label
        if (timeoutLabel != nil) {
            [timeoutLabel setFrameOrigin:NSMakePoint([timeoutLabel frame].origin.x, [timeoutLabel frame].origin.y - (m.size.height - oldHeight))];
        }
        // Set panel's new width and height
        NSSize panelSize = [[[panel panel] contentView] frame].size;
        panelSize.height += m.size.height - oldHeight;
        panelSize.width += m.size.width - oldWidth;
        [[panel panel] setContentSize:panelSize];
        
        [panel addMinWidth:[controlMatrix frame].size.width + 8.0f];
    }
    else if (expandingLabel != nil) {
        [panel addMinWidth:[expandingLabel frame].size.width];
    }
    else if (timeoutLabel != nil) {
        [panel addMinWidth:[timeoutLabel frame].size.width];
    }
    // Add default controls
    if (controlMatrix != nil && ![[icon controls] containsObject:controlMatrix]) {
        [icon addControl:controlMatrix];
    }
}

- (void) setButtons {
    cancelButton = 0;
	unsigned i;
	struct { NSString *key; NSButton *button; } const buttons[] = {
		{ @"button1", button1 },
		{ @"button2", button2 },
		{ @"button3", button3 }
	};

	float minWidth = 2 * 20.0f; // margin
	for (i = 0; i != sizeof(buttons)/sizeof(buttons[0]); i++) {
		[self setTitle:[options optValue:buttons[i].key] forButton:buttons[i].button];
        if ([[self options] hasOpt:@"cancel"] && [[options optValue:@"cancel"] isEqualToString:buttons[i].key]) {
            [buttons[i].button setKeyEquivalent:@"\e"];
            cancelButton = i+1;
        }
        else if ([[options optValue:buttons[i].key] isEqualToString:@"Cancel"]) {
            [buttons[i].button setKeyEquivalent:@"\e"];
            cancelButton = i+1;
        }
		if ([buttons[i].button isHidden] == NO) {
			minWidth += NSWidth([buttons[i].button frame]);
		}
	}

	// move button2 so that it aligns with button1
	NSRect r = [button2 frame];
	r.origin.x = NSMinX([button1 frame]) - NSWidth(r);
	[button2 setFrame:r];

	// move button3 to the left
	r = [button3 frame];
	r.origin.x = 12.0f;
	[button3 setFrame:r];
    [panel addMinHeight:28.0f];
}

// Should be called after setButtons, and before resize
- (void) setLabel:(NSString *)labelText {
    if (expandingLabel != nil) {
        if (labelText == nil) {
            labelText = [NSString stringWithString:@""];
        }
        float labelNewHeight = -8.0f;
        NSRect labelRect = [expandingLabel frame];
        float labelHeightDiff = labelNewHeight - labelRect.size.height;
        if (![labelText isEqualToString:@""]) {
            [expandingLabel setStringValue:labelText];
            NSTextStorage *textStorage = [[[NSTextStorage alloc] initWithString: labelText]autorelease];
            NSTextContainer *textContainer = [[[NSTextContainer alloc] initWithContainerSize:NSMakeSize(labelRect.size.width, FLT_MAX)] autorelease];
            NSLayoutManager *layoutManager = [[[NSLayoutManager alloc]init] autorelease];
            [layoutManager addTextContainer: textContainer];
            [textStorage addLayoutManager: layoutManager];
            [layoutManager glyphRangeForTextContainer:textContainer];
            labelNewHeight = [layoutManager usedRectForTextContainer:textContainer].size.height;
            labelHeightDiff = labelNewHeight - labelRect.size.height;
            // Set label's new height
            NSRect l = NSMakeRect(labelRect.origin.x, labelRect.origin.y - labelHeightDiff, labelRect.size.width, labelNewHeight);
            [panel addControl:expandingLabel];
            [expandingLabel setFrame: l];
        }
        else {
            [expandingLabel setHidden:YES];
            expandingLabel = nil;
        }
        if (controlMatrix != nil) {
            [controlMatrix setFrameOrigin:NSMakePoint([controlMatrix frame].origin.x, [controlMatrix frame].origin.y - labelHeightDiff)];
        }
        if (timeoutLabel != nil) {
            [timeoutLabel setFrameOrigin:NSMakePoint([timeoutLabel frame].origin.x, [timeoutLabel frame].origin.y - labelHeightDiff)];
        }
        // Set panel's new width and height
        NSSize p = [[[panel panel] contentView] frame].size;
        p.height += labelHeightDiff;
        [[panel panel] setContentSize:p];
    }
}

- (void) setTimeoutLabel {
    if (timeoutLabel != nil) {
        float labelNewHeight = -4.0f;
        NSRect labelRect = [timeoutLabel frame];
        float labelHeightDiff = labelNewHeight - labelRect.size.height;
        [timeoutLabel setStringValue:[self formatSecondsForString:(int)timeout]];
        if (![[timeoutLabel stringValue] isEqualToString:@""] && timeout != 0.0f) {
            NSTextStorage *textStorage = [[[NSTextStorage alloc] initWithString: [timeoutLabel stringValue]]autorelease];
            NSTextContainer *textContainer = [[[NSTextContainer alloc] initWithContainerSize:NSMakeSize(labelRect.size.width, FLT_MAX)] autorelease];
            NSLayoutManager *layoutManager = [[[NSLayoutManager alloc]init] autorelease];
            [layoutManager addTextContainer: textContainer];
            [textStorage addLayoutManager: layoutManager];
            [layoutManager glyphRangeForTextContainer:textContainer];
            labelNewHeight = [layoutManager usedRectForTextContainer:textContainer].size.height;
            labelHeightDiff = labelNewHeight - labelRect.size.height;
            // Set label's new height
            NSRect l = NSMakeRect(labelRect.origin.x, 48.0f, labelRect.size.width, labelNewHeight);
            [timeoutLabel setFrame: l];
            if (![[icon controls] containsObject:timeoutLabel]) {
                [icon addControl:timeoutLabel];
            }
        }
        else {
            [timeoutLabel setHidden:YES];
            timeoutLabel = nil;
        }
        // Set panel's new width and height
        NSSize p = [[[panel panel] contentView] frame].size;
        p.height += labelHeightDiff;
        [[panel panel] setContentSize:p];
    }
}

- (BOOL)allowEmptyReturn {
    return ![options hasOpt:@"value-required"];
}

// This must be subclassed for each control. Each control must provide additional logic pertaining to their specific return values
- (BOOL) isReturnValueEmpty {
    return NO;
}

- (NSString *) returnValueEmptyText {
    return @"An input is required, please try again.";
}

- (void) returnValueEmptySheet {
    NSString *message = [self returnValueEmptyText];
    if ([options hasOpt:@"empty-text"]) {
        message = [options optValue:@"empty-text"];
    }
    NSAlert *alertSheet = [[NSAlert alloc] init];
    [alertSheet addButtonWithTitle:@"Okay"];
    [alertSheet setIcon:[icon iconFromName:@"caution"]];
    [alertSheet setMessageText:message];
    [alertSheet beginSheetModalForWindow:[panel panel] modalDelegate:self didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:nil];
}

- (void) controlHasFinished:(int)button {
    controlExitStatus = button;
    switch (button) {
        case 1: controlExitStatusString = [button1 title]; break;
        case 2: controlExitStatusString = [button2 title]; break;
        case 3: controlExitStatusString = [button3 title]; break;
    }
    if (button == cancelButton) {
        controlReturnValues = [NSMutableArray array];
    }
    else {
        if (![self allowEmptyReturn] && [self isReturnValueEmpty]) {
            [self returnValueEmptySheet];
            return;
        }
    }
    [self stopControl];
}

- (void) alertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
    if (controlMatrix != nil && [[controlMatrix cells] count]) {
        if ([controlMatrix selectedCell]) {
            [controlMatrix selectCellAtRow:[controlMatrix selectedRow] column:[controlMatrix selectedColumn]];
        }
    }
    else if (controlItems != nil && [controlItems count]) {
        [[panel panel] makeFirstResponder:[controlItems objectAtIndex:0]];
    }
}

- (IBAction) button1Pressed:(id)sender {
    [controlReturnValues removeAllObjects];
    [self controlHasFinished:1];
}

- (IBAction) button2Pressed:(id)sender {
    [controlReturnValues removeAllObjects];
    [self controlHasFinished:2];
}

- (IBAction) button3Pressed:(id)sender {
    [controlReturnValues removeAllObjects];
    [self controlHasFinished:3];
}

@end
