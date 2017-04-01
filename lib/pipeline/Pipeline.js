// Generated by CoffeeScript 1.7.1
(function() {
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  cas.Pipeline = (function() {
    Pipeline.fNRowsAvailable = 0;

    Pipeline.fAllRowsRung = false;

    function Pipeline(inputStage) {
      this.getRowSource = __bind(this.getRowSource, this);
      this.fInputStage = inputStage;
    }

    Pipeline.prototype.getNBells = function() {
      return this.fRowAccumulator.getNBells();
    };

    Pipeline.prototype.start = function() {
      var errorCorrecter, i, nextCorrecter, _i, _ref;
      this.fErrorCorrectors = this.fInputStage.getErrorCorrecters();
      this.fRowAccumulator = new cas.RowAccumulator(this);
      if ((this.fErrorCorrectors == null) || this.fErrorCorrectors.length === 0) {
        this.fFirstErrorCorrecter = this.fRowAccumulator;
      } else {
        errorCorrecter = this.fErrorCorrectors[0];
        this.fFirstErrorCorrecter = errorCorrecter;
        for (i = _i = 1, _ref = this.fErrorCorrectors.length; 1 <= _ref ? _i < _ref : _i > _ref; i = 1 <= _ref ? ++_i : --_i) {
          nextCorrecter = this.fErrorCorrectors[i];
          errorCorrecter.setNextStage(nextCorrecter);
          errorCorrecter = nextCorrecter;
        }
        errorCorrecter.setNextStage(this.fRowAccumulator);
      }
      return this.fInputStage.startLoad(this);
    };

    Pipeline.prototype.receiveBong = function(bong) {
      return this.fFirstErrorCorrecter.receiveBong(bong);
    };

    Pipeline.prototype.notifyInputComplete = function() {
      return this.fFirstErrorCorrecter.notifyInputComplete();
    };

    Pipeline.prototype.notifyInputError = function(msg) {
      console.error("Input failed: " + msg);
      if (this.fUI != null) {
        return this.fUI.notifyInputError(msg);
      }
    };

    Pipeline.prototype.rowsAvailable = function(nrows) {
      this.fNRowsAvailable = nrows;
      this.rowSource = this.getRowSource(nrows);
      if (this.fCurrentVisualiser != null) {
        return this.fCurrentVisualiser.newRowsAvailable(rowSource);
      }
    };

    Pipeline.prototype.getRawTouchData = function() {
      if (this.fAllRowsRung) {
        return this.getRowSource(this.fNRowsAvailable);
      }
      return null;
    };

    Pipeline.prototype.getRowSource = function(nrows) {
      return {
        getNRows: function() {
          return nrows;
        },
        getRow: (function(_this) {
          return function(i) {
            return _this.fRowAccumulator.getRow(i);
          };
        })(this),
        getNBells: (function(_this) {
          return function() {
            if (_this.fRowAccumulator != null) {
              return _this.fRowAccumulator.getNBells();
            } else {
              return 0;
            }
          };
        })(this)
      };
    };

    Pipeline.prototype.notifyLastRowRung = function() {
      this.fAllRowsRung = true;
      if (this.fCurrentVisualiser != null) {
        return this.fCurrentVisualiser.notifyLastRowRung();
      }
    };

    Pipeline.prototype.setVisualiser = function(visualiser) {
      var existingVisualiserData, rowSource, _ref;
      visualiser.setAnalysisListener(this);
      this.fCurrentVisualiser = visualiser;
      existingVisualiserData = this.fCurrentVisualiser.getAveragedTouchData();
      if (existingVisualiserData.getNRows() > 0) {
        if ((_ref = this.fUI) != null) {
          _ref.loadRows(existingVisualiserData);
        }
      }
      rowSource = this.getRowSource(this.fNRowsAvailable);
      this.fCurrentVisualiser.newRowsAvailable(rowSource);
      if (this.fAllRowsRung) {
        return this.fCurrentVisualiser.notifyLastRowRung();
      }
    };

    Pipeline.prototype.setUI = function(ui) {
      return this.fUI = ui;
    };

    Pipeline.prototype.newAveragedRowAvailable = function() {};

    Pipeline.prototype.analysisComplete = function() {
      var outFn;
      outFn = function(string) {
        var elem;
        elem = document.getElementById('output');
        elem.innerHTML += string;
        return elem.innerHTML += '<br>';
      };
      return this.fCurrentVisualiser.getAveragedTouchData().outputStats(outFn, true);
    };

    return Pipeline;

  })();

}).call(this);