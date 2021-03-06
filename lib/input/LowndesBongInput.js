// Generated by CoffeeScript 1.7.1
(function() {
  var __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  cas.LowndesBongInput = (function(_super) {
    __extends(LowndesBongInput, _super);

    LowndesBongInput.fTimesHeardTreble = 0;

    LowndesBongInput.fSeenFirstBong = false;

    function LowndesBongInput(filename) {
      LowndesBongInput.__super__.constructor.call(this, filename);
      this.fLastTime = 0;
      this.fHighTime = 0;
    }

    LowndesBongInput.prototype.getErrorCorrecters = function() {
      var errorCorrectors;
      errorCorrectors = [];
      errorCorrectors.push(new cas.SensorEchoCorrecter());
      errorCorrectors.push(new cas.ExtraneousStrikeCorrector());
      errorCorrectors.push(new cas.RowOverlapCorrector());
      errorCorrectors.push(new cas.StrokeCorrecter());
      return errorCorrectors;
    };

    LowndesBongInput.prototype.processLine = function(line) {
      var b, bong, stroke, t;
      if (line.length !== 10) {
        throw new Error("Format error in Lowndes file - line unexpected length: " + line);
        return;
      }
      stroke = this.readStrokeCharacter(line.charAt(0));
      b = this.readBellCharacter(line.charAt(2));
      if (b <= 0) {
        return;
      }
      if (b > this.fNBells) {
        this.fNBells = b;
      }
      t = parseInt(line.substring(6, 10), 16);
      if (isNaN(t)) {
        throw new Error("Format error in Lowndes file - bad hex time: " + line);
        return;
      }
      if (t < this.fLastTime) {
        this.fHighTime += 0x10000;
      }
      this.fLastTime = t;
      bong = new cas.Bong(b, t + this.fHighTime, cas.UNKNOWNSTROKE);
      this.fInputListener.receiveBong(bong);
      return this.fSeenFirstBong = true;
    };

    return LowndesBongInput;

  })(cas.BongInputHelper);

}).call(this);
