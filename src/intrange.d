
// Compiler implementation of the D programming language
// Copyright (c) 1999-2011 by Digital Mars
// All Rights Reserved
// written by KennyTM
// http://www.digitalmars.com
// License for redistribution is by either the Artistic License
// in artistic.txt, or the GNU General Public License in gnu.txt.
// See the included readme.txt for details.


module intrange;
extern(C++):

import mars;
import mtype;
import expression;

/**
This class represents a "sign-extended number", i.e. a 65-bit number, which can
represent all built-in integer types in D. This class is mainly used for
performing value-range propagation only, therefore all arithmetic are done with
saturation, not wrapping as usual.
*/
struct SignExtendedNumber
{
    /// The lower 64-bit of the number.
    uinteger_t value;
    /// The sign (i.e. the most significant bit) of the number.
    bool negative;

    /// Create an uninitialized sign-extended number.
    //this() {}

    /// Create a sign-extended number from an unsigned 64-bit number.
    this(uinteger_t value_)
        { value = value_; negative = false; }
    /// Create a sign-extended number from the lower 64-bit and the sign bit.
    this(uinteger_t value_, bool negative_)
        { value = value_; negative = negative_; }

    /// Create a sign-extended number from a signed 64-bit number.
    static SignExtendedNumber fromInteger(uinteger_t value_);

    /// Get the minimum or maximum value of a sign-extended number.
    static SignExtendedNumber extreme(bool minimum);
    static SignExtendedNumber max();
    static SignExtendedNumber min() { return SignExtendedNumber(0, true); }

    /// Check if the sign-extended number is minimum or zero.
    bool isMinimum() const { return negative && value == 0; }

    /// Compare two sign-extended number.
    //bool operator==(const ref SignExtendedNumber) const;
    //bool operator!=(const ref SignExtendedNumber a) const { return !(this == a); }
    //bool operator<(const ref SignExtendedNumber) const;
    //bool operator>(const ref SignExtendedNumber a) const { return a < this; }
    //bool operator<=(const ref SignExtendedNumber a) const { return !(a < this); }
    //bool operator>=(const ref SignExtendedNumber a) const { return !(this < a); }

    /// Compute the saturated negation of a sign-extended number.
    SignExtendedNumber opNeg() const;

    /// Compute the saturated sum of two sign-extended number.
    SignExtendedNumber opAdd(const ref SignExtendedNumber) const;
    /// Compute the saturated difference of two sign-extended number.
    SignExtendedNumber opSub(const ref SignExtendedNumber a) const;
    /// Compute the saturated product of two sign-extended number.
    SignExtendedNumber opMul(const ref SignExtendedNumber) const;
    /// Compute the saturated quotient of two sign-extended number.
    SignExtendedNumber opDiv(const ref SignExtendedNumber) const;
    /// Compute the saturated modulus of two sign-extended number.
    SignExtendedNumber opMod(const ref SignExtendedNumber) const;

    /// Increase the sign-extended number by 1 (saturated).
    ref SignExtendedNumber opInc();

    /// Compute the saturated shifts of two sign-extended number.
    SignExtendedNumber opShl(const ref SignExtendedNumber) const;
    SignExtendedNumber opShr(const ref SignExtendedNumber) const;
};

/**
This class represents a range of integers, denoted by its lower and upper bounds
(inclusive).
*/
struct IntRange
{
    SignExtendedNumber imin, imax;

    /// Create an uninitialized range.
    //this() {}

    /// Create a range consisting of a single number.
    this(const ref SignExtendedNumber a)
        { imin = a; imax = a; }
    /// Create a range with the lower and upper bounds.
    this(const ref SignExtendedNumber lower, const ref SignExtendedNumber upper) 
        { imin = lower; imax = upper; }
    
    /// Create the tightest range containing all valid integers in the specified
    /// type. 
    static IntRange fromType(Type type);
    /// Create the tightest range containing all valid integers in the type with
    /// a forced signedness. 
    static IntRange fromType(Type type, bool isUnsigned);


    /// Create the tightest range containing all specified numbers.
    static IntRange fromNumbers2(const SignExtendedNumber numbers[2]);
    static IntRange fromNumbers4(const SignExtendedNumber numbers[4]);

    /// Create the widest range possible.
    static IntRange widest();

    /// Cast the integer range to a signed type with the given size mask.
    ref IntRange castSigned(uinteger_t mask);
    /// Cast the integer range to an unsigned type with the given size mask.
    ref IntRange castUnsigned(uinteger_t mask);
    /// Cast the integer range to the dchar type.
    ref IntRange castDchar();

    /// Cast the integer range to a specific type.
    ref IntRange _cast(Type type);
    /// Cast the integer range to a specific type, forcing it to be unsigned.
    ref IntRange castUnsigned(Type type);

    /// Check if this range contains another range.
    bool contains(const ref IntRange a) const;

    /// Check if this range contains 0.
    bool containsZero() const;

    /// Compute the range of the negated absolute values of the original range. 
    IntRange absNeg() const;

    /// Compute the union of two ranges.
    IntRange unionWith(const ref IntRange other) const;
    void unionOrAssign(const ref IntRange other, ref bool union_);

    /// Dump the content of the integer range to the console.
    const ref IntRange dump(const(char)* funcName, Expression e) const; 

    /// Split the range into two nonnegative- and negative-only subintervals.
    void splitBySign(ref IntRange negRange, ref bool hasNegRange,
                     ref IntRange nonNegRange, ref bool hasNonNegRange) const;
};

