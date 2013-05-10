# NSLayoutConstraint+ExpressionFormat

## Installation

## Contributing
Please feel free to [fork the code](https://github.com/enderlabs/NSLayoutConstraint-ExpressionFormat), and submit pull requests for any new features or fixes.

## Usage

Auto Layout uses a series of linear equations as constraints to determine the size and position of views. This category allows you to declare these equations in a straightforward, string-based syntax.

### Grammar

     ATTRIBUTE = "left"
               | "right"
               | "top"
               | "bottom"
               | "leading"
               | "trailing"
               | "width"
               | "height"
               | "centerX"
               | "centerY"
               | "baseline" ;
     IDENTIFIER = [_a-zA-Z][_a-zA-Z0-9]* ;
     NUMERAL = [0-9]+("."[0-9]+)? ;
     MUL_OPERATOR = "*" ;
     EQ_OPERATOR = "=" ;
     GTE_OPERATOR = ">=" ;
     LTE_OPERATOR = "<=" ;
     SUB_OPERATOR = "-" ;
     ADD_OPERATOR = "+" ;
     DOT = "." ;
     EOF = <end of file/string> ;

     expression = identifierAttributePair relationOperator rightSubexpression EOF ;
     relationOperator = EQ_OPERATOR
                      | GTE_OPERATOR
                      | LTE_OPERATOR ;
     rightSubexpression = identifierAttributePair scaleExpression? addExpression?
                        | constant ;
     scaleExpression = MUL_OPERATOR constant ;
     addExpression = (ADD_OPERATOR | SUB_OPERATOR) constant ;
     constant = SUB_OPERATOR? (IDENTIFIER | NUMERAL) ;
     identifierAttributePair = IDENTIFIER DOT ATTRIBUTE ;