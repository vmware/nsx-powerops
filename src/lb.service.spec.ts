import { TestBed } from '@angular/core/testing';

import { LBService } from './lb.service';

describe('LBService', () => {
  let service: LBService;

  beforeEach(() => {
    TestBed.configureTestingModule({});
    service = TestBed.inject(LBService);
  });

  it('should be created', () => {
    expect(service).toBeTruthy();
  });
});
