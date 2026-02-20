enum SortCriterion { date, name, distance, duration }

enum SortDirection { ascending, descending }

class SortState {
  SortCriterion criterion;
  SortDirection direction;

  SortState({
    this.criterion = SortCriterion.date,
    this.direction = SortDirection.descending,
  });

  void set(SortCriterion newCriterion) {
    if (criterion == newCriterion) {
      // If it's the same criterion, just flip the direction
      direction = direction == SortDirection.ascending
          ? SortDirection.descending
          : SortDirection.ascending;
    } else {
      // If it's a new criterion, set it and default to descending
      criterion = newCriterion;
      direction = SortDirection.descending;
    }
  }
}
